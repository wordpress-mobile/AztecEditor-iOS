package org.wordpress.mediapicker.source;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Parcel;
import android.provider.MediaStore;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.widget.ImageView;

import com.android.volley.toolbox.ImageLoader;

import org.wordpress.mediapicker.MediaItem;
import org.wordpress.mediapicker.MediaUtils;
import org.wordpress.mediapicker.R;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * A {@link org.wordpress.mediapicker.source.MediaSource} that loads images from the device
 * {@link android.provider.MediaStore}.
 */

public class MediaSourceDeviceImages implements MediaSource {
    // Columns to query from the thumbnail MediaStore database
    private static final String[] THUMBNAIL_QUERY_COLUMNS = {
            MediaStore.Images.Thumbnails._ID,
            MediaStore.Images.Thumbnails.DATA,
            MediaStore.Images.Thumbnails.IMAGE_ID
    };
    // Columns to query from the image MediaStore database
    private static final String[] IMAGE_QUERY_COLUMNS = {
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.DATE_TAKEN,
            MediaStore.Images.Media.ORIENTATION
    };

    protected final List<MediaItem> mMediaItems;

    protected Context               mContext;

    private OnMediaChange                 mListener;
    private AsyncTask<Void, String, Void> mGatheringTask;

    public MediaSourceDeviceImages() {
        mMediaItems = new ArrayList<>();
    }

    protected List<MediaItem> createMediaItems() {
        Cursor thumbnailCursor = MediaUtils.getMediaStoreThumbnails(mContext.getContentResolver(),
                THUMBNAIL_QUERY_COLUMNS);
        Map<String, String> thumbnailData = MediaUtils.getMediaStoreThumbnailData(thumbnailCursor,
                MediaStore.Images.Thumbnails.DATA,
                MediaStore.Images.Thumbnails.IMAGE_ID);

        return MediaUtils.createMediaItems(thumbnailData,
                MediaStore.Images.Media.query(mContext.getContentResolver(),
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                IMAGE_QUERY_COLUMNS, null, null,
                MediaStore.MediaColumns.DATE_MODIFIED + " DESC"),
                MediaUtils.BackgroundFetchThumbnail.TYPE_IMAGE);
    }

    @Override
    public void gather(Context context) {
        // cancel the current gather task
        if (mGatheringTask != null) {
            mGatheringTask.cancel(true);
        }

        // store reference to latest Context
        mContext = context;

        // start gathering
        mGatheringTask = new GatherDeviceImagesTask();
        mGatheringTask.execute();
    }

    @Override
    public void cleanup() {
        if (mGatheringTask != null) {
            // cancel gathering media data immediately, do not wait for the task to finish
            mGatheringTask.cancel(true);
        }
        mMediaItems.clear();
    }

    @Override
    public void setListener(final OnMediaChange listener) {
        mListener = listener;
    }

    @Override
    public int getCount() {
        return mMediaItems.size();
    }

    @Override
    public MediaItem getMedia(int position) {
        return (position < mMediaItems.size()) ? mMediaItems.get(position) : null;
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent, LayoutInflater inflater, final ImageLoader.ImageCache cache) {
        if (convertView == null) {
            convertView = inflater.inflate(R.layout.media_item_image, parent, false);
        }

        final MediaItem mediaItem = mMediaItems.get(position);
        if (convertView != null && mediaItem != null) {
            final ImageView imageView = (ImageView) convertView.findViewById(R.id.image_view_background);
            final Uri imageSource;
            if (mediaItem.getPreviewSource() != null && !mediaItem.getPreviewSource().toString().isEmpty()) {
                imageSource = mediaItem.getPreviewSource();
            } else {
                imageSource = mediaItem.getSource();
            }

            if (imageView != null) {
                int width = imageView.getWidth();
                int height = imageView.getHeight();

                if (width <= 0 || height <= 0) {
                    imageView.getViewTreeObserver().addOnPreDrawListener(new ViewTreeObserver.OnPreDrawListener() {
                        @Override
                        public boolean onPreDraw() {
                            int width = imageView.getWidth();
                            int height = imageView.getHeight();
                            MediaUtils.fadeMediaItemImageIntoView(imageSource, cache, imageView, mediaItem,
                                    width, height, MediaUtils.BackgroundFetchThumbnail.TYPE_IMAGE);
                            imageView.getViewTreeObserver().removeOnPreDrawListener(this);
                            return true;
                        }
                    });
                } else {
                    MediaUtils.fadeMediaItemImageIntoView(imageSource, cache, imageView, mediaItem,
                            width, height, MediaUtils.BackgroundFetchThumbnail.TYPE_IMAGE);
                }
            }
        }

        return convertView;
    }

    @Override
    public boolean onMediaItemSelected(MediaItem mediaItem, boolean selected) {
        return !selected;
    }

    /**
     * Clears the current media items then adds the provided items.
     */
    protected void setMediaItems(List<MediaItem> mediaItems) {
        mMediaItems.clear();
        mMediaItems.addAll(mediaItems);
    }

    /**
     * Invokes
     * {@link org.wordpress.mediapicker.source.MediaSource.OnMediaChange#onMediaLoaded(boolean)}
     * if {@link #mListener} is not null.
     *
     * @param success
     * passthrough parameter
     */
    protected void notifyMediaLoaded(boolean success) {
        if (mListener != null) {
            mListener.onMediaLoaded(success);
        }
    }

    /**
     * Gathers media items on a background thread.
     */
    protected class GatherDeviceImagesTask extends AsyncTask<Void, String, Void> {
        @Override
        protected void onPreExecute() {
            // delete references to any existing media items before gathering
            mMediaItems.clear();
        }

        @Override
        protected Void doInBackground(Void... params) {
            mMediaItems.addAll(createMediaItems());
            return null;
        }

        @Override
        protected void onPostExecute(Void result) {
            notifyMediaLoaded(true);
            nullGatheringReference();
        }

        @Override
        protected void onCancelled(Void result) {
            nullGatheringReference();
        }

        /**
         * Sets MediaSourceDeviceImages.this.mGatheringTask to null if it's referencing this.
         */
        protected void nullGatheringReference() {
            if (mGatheringTask == this) {
                mGatheringTask = null;
            }
        }
    }

    /**
     * {@link android.os.Parcelable} interface
     */

    public static final Creator<MediaSourceDeviceImages> CREATOR =
            new Creator<MediaSourceDeviceImages>() {
                public MediaSourceDeviceImages createFromParcel(Parcel in) {
                    List<MediaItem> parcelData = new ArrayList<>();
                    in.readTypedList(parcelData, MediaItem.CREATOR);
                    MediaSourceDeviceImages newItem = new MediaSourceDeviceImages();

                    if (parcelData.size() > 0) {
                        newItem.setMediaItems(parcelData);
                    }

                    return newItem;
                }

                public MediaSourceDeviceImages[] newArray(int size) {
                    return new MediaSourceDeviceImages[size];
                }
            };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel destination, int flags) {
        destination.writeTypedList(mMediaItems);
    }
}
