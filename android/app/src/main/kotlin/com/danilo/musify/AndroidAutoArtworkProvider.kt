package com.danilo.musify

import android.content.ContentProvider
import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Rect
import android.graphics.RectF
import android.net.Uri
import android.os.ParcelFileDescriptor
import org.json.JSONObject
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import javax.net.ssl.HttpsURLConnection

private const val ARTWORK_DIRECTORY = "app_flutter/android_auto_artwork"
private const val MAX_ORIGINAL_BYTES = 8L * 1024L * 1024L
private const val MAX_CACHE_BYTES = 96L * 1024L * 1024L
private const val DEFAULT_ARTWORK_SIZE = 512

/**
 * Serves small cached artwork files to Android Auto and Android Automotive OS.
 * Browse results only contain content URIs, never Binder-hosted bitmaps.
 */
class AndroidAutoArtworkProvider : ContentProvider() {
  companion object {
    private val locks = ConcurrentHashMap<String, Any>()
    @Volatile private var lastPruneMillis = 0L
  }

  override fun onCreate(): Boolean = true

  override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
    if (mode != "r") throw FileNotFoundException("Artwork is read-only")
    val context = context ?: throw FileNotFoundException("Missing context")
    val key = extractKey(uri)
    // A fixed, bounded size avoids altering audio_service's concrete service class.
    // This keeps playback stable while remaining suitable for car list/grid artwork.
    val size = DEFAULT_ARTWORK_SIZE
    val directory = artworkDirectory(context).apply { mkdirs() }
    val output = File(directory, "${key}_${size}.jpg")

    val lock = locks.getOrPut(key) { Any() }
    try {
      synchronized(lock) {
        if (!output.isFile || output.length() == 0L) {
          val bitmap = renderKey(context, directory, key, size, 0)
            ?: throw FileNotFoundException("Artwork unavailable")
          try {
            writeJpegAtomically(bitmap, output)
          } finally {
            bitmap.recycle()
          }
        }
        output.setLastModified(System.currentTimeMillis())
        pruneCache(directory, output)
      }
    } finally {
      locks.remove(key, lock)
    }
    return ParcelFileDescriptor.open(output, ParcelFileDescriptor.MODE_READ_ONLY)
  }

  private fun extractKey(uri: Uri): String {
    val expectedAuthority = "${context?.packageName}.androidauto.artwork"
    if (uri.authority != expectedAuthority || uri.pathSegments.size != 2 ||
      uri.pathSegments[0] != "art"
    ) {
      throw FileNotFoundException("Invalid artwork URI")
    }
    val key = uri.pathSegments[1]
    if (!key.matches(Regex("[a-f0-9]{64}"))) {
      throw FileNotFoundException("Invalid artwork key")
    }
    return key
  }

  private fun renderKey(
    context: Context,
    directory: File,
    key: String,
    size: Int,
    depth: Int,
  ): Bitmap? {
    if (depth > 2) return null
    val specFile = File(directory, "$key.json")
    if (!specFile.isFile || specFile.length() > 128L * 1024L) return null
    val spec = runCatching { JSONObject(specFile.readText(Charsets.UTF_8)) }.getOrNull()
      ?: return null
    return when (spec.optString("kind")) {
      "single" -> loadSingle(context, directory, key, spec.optString("source"), size)
      "mosaic" -> {
        val array = spec.optJSONArray("keys") ?: return null
        val keys = buildList {
          for (index in 0 until minOf(array.length(), 4)) {
            val childKey = array.optString(index)
            if (childKey.matches(Regex("[a-f0-9]{64}"))) add(childKey)
          }
        }
        renderMosaic(context, directory, keys, size, depth + 1)
      }
      else -> null
    }
  }

  private fun loadSingle(
    context: Context,
    directory: File,
    key: String,
    source: String,
    size: Int,
  ): Bitmap? {
    val original = File(directory, "$key.original")
    if (!original.isFile || original.length() == 0L) {
      if (!materializeSource(context, source, original)) return null
    }
    return decodeSampledSquare(original, size)
  }

  private fun materializeSource(context: Context, source: String, target: File): Boolean {
    if (source == "cached:") return target.isFile && target.length() > 0L
    val uri = runCatching { Uri.parse(source) }.getOrNull() ?: return false
    val temporary = File(target.parentFile, "${target.name}.${System.nanoTime()}.tmp")
    return try {
      when (uri.scheme) {
        "https" -> downloadHttps(uri, temporary)
        "file" -> File(uri.path ?: return false).inputStream().use {
          copyLimited(it, temporary)
        }
        "content", "android.resource" -> {
          if (uri.authority == "${context.packageName}.androidauto.artwork") return false
          context.contentResolver.openInputStream(uri)?.use {
            copyLimited(it, temporary)
          } ?: false
        }
        else -> false
      }.also { success ->
        if (success && temporary.isFile && temporary.length() > 0L) {
          if (target.exists()) temporary.delete() else temporary.renameTo(target)
        }
      }
    } catch (_: Exception) {
      false
    } finally {
      if (temporary.exists()) temporary.delete()
    }
  }

  private fun downloadHttps(uri: Uri, target: File): Boolean {
    val connection = URL(uri.toString()).openConnection() as? HttpsURLConnection
      ?: return false
    return try {
      connection.instanceFollowRedirects = true
      connection.connectTimeout = 4_000
      connection.readTimeout = 7_000
      connection.setRequestProperty("User-Agent", "Musify/11.4.4")
      connection.connect()
      if (connection.responseCode != HttpURLConnection.HTTP_OK ||
        connection.url.protocol != "https" ||
        connection.contentLengthLong > MAX_ORIGINAL_BYTES ||
        connection.contentType?.startsWith("image/") != true
      ) {
        false
      } else {
        connection.inputStream.use { copyLimited(it, target) }
      }
    } finally {
      connection.disconnect()
    }
  }

  private fun copyLimited(input: InputStream, target: File): Boolean {
    FileOutputStream(target).use { output ->
      val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
      var total = 0L
      while (true) {
        val read = input.read(buffer)
        if (read < 0) break
        total += read
        if (total > MAX_ORIGINAL_BYTES) return false
        output.write(buffer, 0, read)
      }
      output.fd.sync()
      return total > 0L
    }
  }

  private fun decodeSampledSquare(file: File, size: Int): Bitmap? {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    BitmapFactory.decodeFile(file.path, bounds)
    if (bounds.outWidth <= 0 || bounds.outHeight <= 0 ||
      bounds.outWidth > 16_384 || bounds.outHeight > 16_384
    ) {
      return null
    }
    var sample = 1
    while (bounds.outWidth / (sample * 2) >= size &&
      bounds.outHeight / (sample * 2) >= size
    ) {
      sample *= 2
    }
    val decoded = BitmapFactory.decodeFile(
      file.path,
      BitmapFactory.Options().apply {
        inSampleSize = sample
        inPreferredConfig = Bitmap.Config.ARGB_8888
      },
    ) ?: return null
    return centerCrop(decoded, size, size).also {
      if (it !== decoded) decoded.recycle()
    }
  }

  private fun renderMosaic(
    context: Context,
    directory: File,
    keys: List<String>,
    size: Int,
    depth: Int,
  ): Bitmap? {
    if (keys.isEmpty()) return null
    if (keys.size == 1) return renderKey(context, directory, keys.first(), size, depth)
    val selected = if (keys.size >= 4) keys.take(4) else keys.take(2)
    val result = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(result)
    canvas.drawColor(Color.BLACK)
    val destinations = if (selected.size == 4) {
      listOf(
        RectF(0f, 0f, size / 2f, size / 2f),
        RectF(size / 2f, 0f, size.toFloat(), size / 2f),
        RectF(0f, size / 2f, size / 2f, size.toFloat()),
        RectF(size / 2f, size / 2f, size.toFloat(), size.toFloat()),
      )
    } else {
      listOf(
        RectF(0f, 0f, size / 2f, size.toFloat()),
        RectF(size / 2f, 0f, size.toFloat(), size.toFloat()),
      )
    }
    var drawn = 0
    selected.forEachIndexed { index, childKey ->
      val child = renderKey(context, directory, childKey, size, depth) ?: return@forEachIndexed
      drawCenterCrop(canvas, child, destinations[index])
      child.recycle()
      drawn++
    }
    if (drawn == 0) {
      result.recycle()
      return null
    }
    return result
  }

  private fun centerCrop(source: Bitmap, width: Int, height: Int): Bitmap {
    val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    drawCenterCrop(Canvas(output), source, RectF(0f, 0f, width.toFloat(), height.toFloat()))
    return output
  }

  private fun drawCenterCrop(canvas: Canvas, source: Bitmap, destination: RectF) {
    val sourceAspect = source.width.toFloat() / source.height
    val destinationAspect = destination.width() / destination.height()
    val sourceRect = if (sourceAspect > destinationAspect) {
      val width = (source.height * destinationAspect).toInt()
      val left = (source.width - width) / 2
      Rect(left, 0, left + width, source.height)
    } else {
      val height = (source.width / destinationAspect).toInt()
      val top = (source.height - height) / 2
      Rect(0, top, source.width, top + height)
    }
    canvas.drawBitmap(source, sourceRect, destination, null)
  }

  private fun writeJpegAtomically(bitmap: Bitmap, output: File) {
    val temporary = File(output.parentFile, "${output.name}.${System.nanoTime()}.tmp")
    FileOutputStream(temporary).use { stream ->
      if (!bitmap.compress(Bitmap.CompressFormat.JPEG, 88, stream)) {
        throw FileNotFoundException("Unable to encode artwork")
      }
      stream.fd.sync()
    }
    if (output.exists()) temporary.delete() else if (!temporary.renameTo(output)) {
      temporary.delete()
      throw FileNotFoundException("Unable to cache artwork")
    }
  }

  private fun pruneCache(directory: File, protectedFile: File) {
    val now = System.currentTimeMillis()
    if (now - lastPruneMillis < 60L * 60L * 1000L) return
    lastPruneMillis = now
    val cacheFiles = directory.listFiles { file ->
      file.isFile && (file.name.endsWith(".jpg") || file.name.endsWith(".original"))
    }?.sortedBy { it.lastModified() } ?: return
    var total = cacheFiles.sumOf { it.length() }
    for (file in cacheFiles) {
      if (total <= MAX_CACHE_BYTES) break
      if (file == protectedFile) continue
      val length = file.length()
      if (file.delete()) total -= length
    }
  }

  private fun artworkDirectory(context: Context) = File(
    context.applicationInfo.dataDir,
    ARTWORK_DIRECTORY,
  )

  override fun getType(uri: Uri): String = "image/jpeg"
  override fun query(
    uri: Uri,
    projection: Array<out String>?,
    selection: String?,
    selectionArgs: Array<out String>?,
    sortOrder: String?,
  ): Cursor? = null
  override fun insert(uri: Uri, values: ContentValues?): Uri? = null
  override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = 0
  override fun update(
    uri: Uri,
    values: ContentValues?,
    selection: String?,
    selectionArgs: Array<out String>?,
  ): Int = 0
}
