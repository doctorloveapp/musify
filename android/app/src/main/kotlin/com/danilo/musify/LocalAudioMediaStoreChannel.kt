package com.danilo.musify

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import android.util.Size
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Small, app-owned MediaStore bridge.
 *
 * Permission is checked before any ContentResolver call and every Flutter
 * invocation is completed at most once. This deliberately avoids the
 * permission-error fall-through in on_audio_query_plus that can call both
 * result.error() and result.success().
 */
internal class LocalAudioMediaStoreChannel(
  context: Context,
  messenger: BinaryMessenger,
) {
  private val appContext = context.applicationContext
  private val channel = MethodChannel(messenger, CHANNEL_NAME)
  private val worker = Executors.newSingleThreadExecutor()
  private val mainHandler = Handler(Looper.getMainLooper())

  init {
    channel.setMethodCallHandler(::handleCall)
  }

  fun dispose() {
    channel.setMethodCallHandler(null)
    worker.shutdownNow()
  }

  private fun handleCall(call: MethodCall, rawResult: MethodChannel.Result) {
    val result = ReplyOnce(rawResult)
    when (call.method) {
      "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
      "querySongs" -> {
        if (!hasAudioPermission()) {
          result.error(
            ERROR_MISSING_PERMISSION,
            "READ_MEDIA_AUDIO (or legacy storage access) is not granted",
            null,
          )
          return
        }
        worker.execute {
          try {
            val songs = querySongs()
            mainHandler.post { result.success(songs) }
          } catch (error: SecurityException) {
            mainHandler.post {
              result.error(ERROR_MISSING_PERMISSION, error.message, null)
            }
          } catch (error: Exception) {
            mainHandler.post {
              result.error(ERROR_QUERY_FAILED, error.message, null)
            }
          }
        }
      }
      "queryArtwork" -> {
        if (!hasAudioPermission()) {
          result.error(
            ERROR_MISSING_PERMISSION,
            "READ_MEDIA_AUDIO (or legacy storage access) is not granted",
            null,
          )
          return
        }
        val mediaId = (call.argument<Number>("id"))?.toLong()
        val requestedSize = (call.argument<Number>("size"))?.toInt() ?: 512
        if (mediaId == null || mediaId < 0) {
          result.error("InvalidArguments", "A valid MediaStore id is required", null)
          return
        }
        worker.execute {
          val artwork = queryArtwork(mediaId, requestedSize.coerceIn(64, 2048))
          mainHandler.post { result.success(artwork) }
        }
      }
      else -> result.notImplemented()
    }
  }

  private fun hasAudioPermission(): Boolean {
    val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      Manifest.permission.READ_MEDIA_AUDIO
    } else {
      Manifest.permission.READ_EXTERNAL_STORAGE
    }
    return appContext.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
  }

  private fun querySongs(): List<Map<String, Any?>> {
    // Repeat the native check on the worker immediately before ContentResolver.
    if (!hasAudioPermission()) {
      throw SecurityException("Audio permission was revoked before the query")
    }

    val collection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL)
    } else {
      MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
    }
    val projection = mutableListOf(
      MediaStore.Audio.Media._ID,
      MediaStore.Audio.Media.TITLE,
      MediaStore.Audio.Media.DISPLAY_NAME,
      MediaStore.Audio.Media.DURATION,
      MediaStore.Audio.Media.SIZE,
      MediaStore.Audio.Media.DATE_ADDED,
      MediaStore.Audio.Media.DATE_MODIFIED,
      MediaStore.Audio.Media.ARTIST,
      MediaStore.Audio.Media.ALBUM,
      MediaStore.Audio.Media.ALBUM_ID,
      MediaStore.Audio.Media.MIME_TYPE,
      MediaStore.Audio.Media.IS_MUSIC,
      MediaStore.Audio.Media.IS_ALARM,
      MediaStore.Audio.Media.IS_NOTIFICATION,
      MediaStore.Audio.Media.IS_RINGTONE,
    )
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      projection += MediaStore.Audio.Media.RELATIVE_PATH
    } else {
      // DATA is a legacy filesystem path. Modern Android playback uses the
      // content URI and never asks MediaStore for this deprecated column.
      projection += MediaStore.Audio.Media.DATA
    }

    val songs = ArrayList<Map<String, Any?>>()
    appContext.contentResolver.query(
      collection,
      projection.toTypedArray(),
      "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} > 0",
      null,
      "${MediaStore.Audio.Media.DATE_ADDED} DESC",
    )?.use { cursor ->
      while (cursor.moveToNext()) {
        val id = cursor.long(MediaStore.Audio.Media._ID) ?: continue
        val displayName = cursor.string(MediaStore.Audio.Media.DISPLAY_NAME).orEmpty()
        val absolutePath = cursor.string(MediaStore.Audio.Media.DATA).orEmpty()
        val relativePath = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
          cursor.string(MediaStore.Audio.Media.RELATIVE_PATH)
        } else {
          null
        }
        val folder = absolutePath
          .takeIf(String::isNotEmpty)
          ?.let { File(it).parent }
          ?: relativePath?.trimEnd('/')

        songs += hashMapOf(
          "id" to id,
          "title" to cursor.string(MediaStore.Audio.Media.TITLE).orEmpty(),
          "displayName" to displayName,
          "data" to absolutePath,
          "uri" to ContentUris.withAppendedId(collection, id).toString(),
          "duration" to cursor.long(MediaStore.Audio.Media.DURATION),
          "size" to (cursor.long(MediaStore.Audio.Media.SIZE) ?: 0L),
          "dateAdded" to cursor.long(MediaStore.Audio.Media.DATE_ADDED),
          "dateModified" to cursor.long(MediaStore.Audio.Media.DATE_MODIFIED),
          "artist" to cursor.string(MediaStore.Audio.Media.ARTIST).cleanMetadata(),
          "album" to cursor.string(MediaStore.Audio.Media.ALBUM).cleanMetadata(),
          "albumId" to cursor.long(MediaStore.Audio.Media.ALBUM_ID),
          "extension" to displayName.substringAfterLast('.', "").ifEmpty { null },
          "mimeType" to cursor.string(MediaStore.Audio.Media.MIME_TYPE),
          "folder" to folder,
          "isMusic" to cursor.boolean(MediaStore.Audio.Media.IS_MUSIC),
          "isAlarm" to cursor.boolean(MediaStore.Audio.Media.IS_ALARM),
          "isNotification" to cursor.boolean(MediaStore.Audio.Media.IS_NOTIFICATION),
          "isRingtone" to cursor.boolean(MediaStore.Audio.Media.IS_RINGTONE),
        )
      }
    }
    return songs
  }

  private fun queryArtwork(mediaId: Long, size: Int): ByteArray? {
    if (!hasAudioPermission()) return null
    val uri = ContentUris.withAppendedId(
      MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
      mediaId,
    )

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
      try {
        val bitmap = appContext.contentResolver.loadThumbnail(
          uri,
          Size(size, size),
          null,
        )
        return bitmap.toJpegBytes()
      } catch (_: Exception) {
        // Some audio providers do not expose thumbnails. Try embedded art.
      }
    }

    val retriever = MediaMetadataRetriever()
    return try {
      retriever.setDataSource(appContext, uri)
      retriever.embeddedPicture
    } catch (_: Exception) {
      null
    } finally {
      try {
        retriever.release()
      } catch (_: Exception) {
        // Nothing to clean up.
      }
    }
  }

  private fun Bitmap.toJpegBytes(): ByteArray {
    val stream = ByteArrayOutputStream()
    compress(Bitmap.CompressFormat.JPEG, 88, stream)
    recycle()
    return stream.toByteArray()
  }

  private fun Cursor.column(name: String): Int = getColumnIndex(name)

  private fun Cursor.long(name: String): Long? {
    val index = column(name)
    return if (index < 0 || isNull(index)) null else getLong(index)
  }

  private fun Cursor.string(name: String): String? {
    val index = column(name)
    return if (index < 0 || isNull(index)) null else getString(index)
  }

  private fun Cursor.boolean(name: String): Boolean? = long(name)?.let { it != 0L }

  private fun String?.cleanMetadata(): String? =
    this?.takeUnless { it.isBlank() || it == MediaStore.UNKNOWN_STRING }

  private class ReplyOnce(private val delegate: MethodChannel.Result) {
    private val submitted = AtomicBoolean(false)

    fun success(value: Any?) {
      if (submitted.compareAndSet(false, true)) delegate.success(value)
    }

    fun error(code: String, message: String?, details: Any?) {
      if (submitted.compareAndSet(false, true)) delegate.error(code, message, details)
    }

    fun notImplemented() {
      if (submitted.compareAndSet(false, true)) delegate.notImplemented()
    }
  }

  private companion object {
    const val CHANNEL_NAME = "com.danilo.musify/local_audio"
    const val ERROR_MISSING_PERMISSION = "MissingPermissions"
    const val ERROR_QUERY_FAILED = "MediaStoreQueryFailed"
  }
}
