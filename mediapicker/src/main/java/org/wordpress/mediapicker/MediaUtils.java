package org.wordpress.mediapicker;

import android.content.ContentResolver;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ThumbnailUtils;
import android.net.Uri;
import android.os.AsyncTask;
import android.provider.MediaStore;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.widget.ImageView;

import com.android.volley.toolbox.ImageLoader;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MediaUtils {
    private static final long FADE_TIME_MS = 250;

    public static void fadeInImage(ImageView imageView, Bitmap image) {
        fadeInImage(imageView, image, FADE_TIME_MS);
    }

    public static void fadeInImage(ImageView imageView, Bitmap image, long duration) {
        if (imageView != null) {
            imageView.setImageBitmap(image);
            Animation alpha = new AlphaAnimation(0.25f, 1.0f);
            alpha.setDuration(duration);
            imageView.startAnimation(alpha);
            // Use the implementation below if you can figure out how to make it work on all devices
            // My Galaxy S3 (4.1.2) would not animate
//            imageView.setImageBitmap(image);
//            ObjectAnimator.ofFloat(imageView, View.ALPHA, 0.25f, 1.0f).setDuration(duration).start();
        }
    }

    public static Cursor getMediaStoreThumbnails(ContentResolver contentResolver, String[] columns) {
        if (contentResolver == null) return null;
        Uri thumbnailUri = MediaStore.Images.Thumbnails.EXTERNAL_CONTENT_URI;
        return MediaStore.Images.Thumbnails.query(contentResolver, thumbnailUri, columns);
    }

    public static Cursor getDeviceMediaStoreVideos(ContentResolver contentResolver, String[] columns) {
        if (contentResolver == null) return null;
        Uri videoUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
        return MediaStore.Video.query(contentResolver, videoUri, columns);
    }

    public static Map<String, String> getMediaStoreThumbnailData(Cursor thumbnailCursor,
                                                                 String dataColumnName,
                                                                 String idColumnName) {
        final Map<String, String> data = new HashMap<>();

        if (thumbnailCursor != null) {
            if (thumbnailCursor.moveToFirst()) {
                do {
                    int dataColumnIndex = thumbnailCursor.getColumnIndex(dataColumnName);
                    int imageIdColumnIndex = thumbnailCursor.getColumnIndex(idColumnName);

                    if (dataColumnIndex != -1 && imageIdColumnIndex != -1) {
                        data.put(thumbnailCursor.getString(imageIdColumnIndex),
                                 thumbnailCursor.getString(dataColumnIndex));
                    }
                } while (thumbnailCursor.moveToNext());
            }

            thumbnailCursor.close();
        }

        return data;
    }

    public static List<MediaItem> createMediaItems(Map<String, String> thumbnailData, Cursor mediaCursor, int type) {
        final List<MediaItem> mediaItems = new ArrayList<>();
        final List<String> ids = new ArrayList<>();

        if (mediaCursor != null) {
            if (mediaCursor.moveToFirst()) {
                do {
                    MediaItem newContent = type == BackgroundFetchThumbnail.TYPE_IMAGE ?
                               getMediaItemFromImageCursor(mediaCursor, thumbnailData) :
                               getMediaItemFromVideoCursor(mediaCursor, thumbnailData);

                    if (newContent != null && !ids.contains(newContent.getTag())) {
                        mediaItems.add(newContent);
                        ids.add(newContent.getTag());
                    }
                } while (mediaCursor.moveToNext());
            }

            mediaCursor.close();
        }

        return mediaItems;
    }

    public static void fadeMediaItemImageIntoView(Uri imageSource, ImageLoader.ImageCache cache,
                                                  ImageView imageView, MediaItem mediaItem,
                                                  int width, int height, int type) {
        if (imageSource != null && !imageSource.toString().isEmpty()) {
            Bitmap imageBitmap = null;
            if (cache != null) {
                imageBitmap = cache.getBitmap(imageSource.toString());
            }

            if (imageBitmap == null) {
                imageView.setImageResource(R.drawable.media_item_placeholder);
                BackgroundFetchThumbnail bgDownload =
                        new MediaUtils.BackgroundFetchThumbnail(imageView,
                                cache,
                                type,
                                width,
                                height,
                                mediaItem.getRotation());
                imageView.setTag(bgDownload);
                bgDownload.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, imageSource);
            } else {
                fadeInImage(imageView, imageBitmap);
            }
        } else {
            imageView.setTag(null);
            imageView.setImageResource(R.drawable.ic_now_wallpaper_white);
        }
    }

    public static class BackgroundFetchThumbnail extends AsyncTask<Uri, String, Bitmap> {
        public static final int TYPE_IMAGE = 0;
        public static final int TYPE_VIDEO = 1;

        private static final int MAX_ACTIVE_FETCHES_DEFAULT = 32;
        private static final List<BackgroundFetchThumbnail> sActiveFetches = new ArrayList<>();

        private WeakReference<ImageView> mReference;
        private ImageLoader.ImageCache mCache;
        private int mType;
        private int mWidth;
        private int mHeight;
        private int mRotation;
        private int mMaxFetches;

        public BackgroundFetchThumbnail(ImageView resultStore, ImageLoader.ImageCache cache, int type, int width, int height, int rotation) {
            mReference = new WeakReference<>(resultStore);
            mMaxFetches = MAX_ACTIVE_FETCHES_DEFAULT;
            mCache = cache;
            mType = type;
            mWidth = width;
            mHeight = height;
            mRotation = rotation;
        }

        @Override
        protected void onPreExecute() {
            super.onPreExecute();

            if (sActiveFetches.size() > mMaxFetches) {
                sActiveFetches.remove(0).cancel(true);
            }

            sActiveFetches.add(this);
        }

        @Override
        protected Bitmap doInBackground(Uri... params) {
            String uri = params[0].toString();
            Bitmap bitmap = null;

            if (mType == TYPE_IMAGE) {
                BitmapFactory.Options options = new BitmapFactory.Options();
                options.inJustDecodeBounds = true;
                BitmapFactory.decodeFile(uri, options);
                options.inJustDecodeBounds = false;
                options.inSampleSize = calculateInSampleSize(options);
                bitmap = BitmapFactory.decodeFile(uri, options);

                if (bitmap != null) {
                    Matrix rotation = new Matrix();
                    rotation.setRotate(mRotation, bitmap.getWidth() / 2.0f, bitmap.getHeight() / 2.0f);
                    bitmap = Bitmap.createBitmap(bitmap, 0, 0, bitmap.getWidth(), bitmap.getHeight(), rotation, false);
                }
            } else if (mType == TYPE_VIDEO) {
                // MICRO_KIND = 96 x 96
                // MINI_KIND  = 512 x 384
                bitmap = ThumbnailUtils.createVideoThumbnail(uri, MediaStore.Video.Thumbnails.MINI_KIND);
            }

            if (mCache != null && bitmap != null) {
                mCache.putBitmap(uri, bitmap);
            }

            return bitmap;
        }

        // http://developer.android.com/training/displaying-bitmaps/load-bitmap.html
        private int calculateInSampleSize(BitmapFactory.Options options) {
            // Raw height and width of image
            final int height = options.outHeight;
            final int width = options.outWidth;
            int inSampleSize = 1;

            if (height > mHeight || width > mWidth) {

                final int halfHeight = height / 2;
                final int halfWidth = width / 2;

                // Calculate the largest inSampleSize value that is a power of 2 and keeps both
                // height and width larger than the requested height and width.
                while ((halfHeight / inSampleSize) > mHeight
                        && (halfWidth / inSampleSize) > mWidth) {
                    inSampleSize *= 2;
                }
            }

            return inSampleSize;
        }

        @Override
        protected void onPostExecute(Bitmap result) {
            sActiveFetches.remove(this);

            ImageView imageView = mReference.get();

            if (imageView != null) {
                if (imageView.getTag() == this) {
                    imageView.setTag(null);
                    if (result == null) {
                        imageView.setImageResource(R.drawable.ic_now_wallpaper_white);
                    } else {
                        fadeInImage(imageView, result);
                    }
                }
            }
        }

        public void setMaxFetches(int maxFetches) {
            mMaxFetches = maxFetches;
        }
    }

    private static MediaItem getMediaItemFromVideoCursor(Cursor videoCursor, Map<String, String> thumbnailData) {
        MediaItem newContent = null;

        int videoIdColumnIndex = videoCursor.getColumnIndex(MediaStore.Video.Media._ID);
        int videoDataColumnIndex = videoCursor.getColumnIndex(MediaStore.Video.Media.DATA);

        if (videoIdColumnIndex != -1) {
            newContent = new MediaItem();
            newContent.setTag(videoCursor.getString(videoIdColumnIndex));
            newContent.setTitle("");

            if (videoDataColumnIndex != -1) {
                newContent.setSource(Uri.parse(videoCursor.getString(videoDataColumnIndex)));
            }
            if (thumbnailData.containsKey(newContent.getTag())) {
                newContent.setPreviewSource(Uri.parse(thumbnailData.get(newContent.getTag())));
            }
        }

        return newContent;
    }

    private static MediaItem getMediaItemFromImageCursor(Cursor imageCursor, Map<String, String> thumbnailData) {
        MediaItem newContent = null;

        int imageIdColumnIndex = imageCursor.getColumnIndex(MediaStore.Images.Media._ID);
        int imageDataColumnIndex = imageCursor.getColumnIndex(MediaStore.Images.Media.DATA);
        int imageOrientationColumnIndex = imageCursor.getColumnIndex(MediaStore.Images.Media.ORIENTATION);

        if (imageIdColumnIndex != -1) {
            newContent = new MediaItem();
            newContent.setTag(imageCursor.getString(imageIdColumnIndex));
            newContent.setTitle("");

            if (imageDataColumnIndex != -1) {
                newContent.setSource(Uri.parse(imageCursor.getString(imageDataColumnIndex)));
            }
            if (thumbnailData.containsKey(newContent.getTag())) {
                newContent.setPreviewSource(Uri.parse(thumbnailData.get(newContent.getTag())));
            }
            if (imageOrientationColumnIndex != -1) {
                newContent.setRotation(imageCursor.getInt(imageOrientationColumnIndex));
            }
        }

        return newContent;
    }
}
