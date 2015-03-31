package org.wordpress.mediapicker.source;

import android.database.Cursor;
import android.net.Uri;
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

public class MediaSourceDeviceVideos extends MediaSourceDeviceImages {
    private static final String[] VIDEO_QUERY_COLUMNS = {
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DATA };
    private static final String[] THUMBNAIL_QUERY_COLUMNS = {
            MediaStore.Video.Media._ID,
            MediaStore.Video.Media.DATA,
            MediaStore.Video.Media.DATE_TAKEN };

    @Override
    protected List<MediaItem> createMediaItems() {
        Cursor thumbnailCursor = MediaUtils.getDeviceMediaStoreVideos(mContext.getContentResolver(),
                THUMBNAIL_QUERY_COLUMNS);
        Map<String, String> thumbnailData = MediaUtils.getMediaStoreThumbnailData(thumbnailCursor,
                MediaStore.Video.Media.DATA,
                MediaStore.Video.Media._ID);

        return MediaUtils.createMediaItems(thumbnailData,
                MediaStore.Images.Media.query(mContext.getContentResolver(),
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                VIDEO_QUERY_COLUMNS, null, null,
                MediaStore.MediaColumns.DATE_MODIFIED + " DESC"),
                MediaUtils.BackgroundFetchThumbnail.TYPE_VIDEO);
    }

    @Override
    public View getView(int position, View convertView, ViewGroup parent, LayoutInflater inflater, final ImageLoader.ImageCache cache) {
        if (convertView == null) {
            convertView = inflater.inflate(R.layout.media_item_video, parent, false);
        }

        if (convertView != null && position < mMediaItems.size()) {
            final MediaItem mediaItem = mMediaItems.get(position);
            final Uri imageSource = mediaItem.getPreviewSource();

            final ImageView imageView = (ImageView) convertView.findViewById(R.id.video_view_background);
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
                                    width, height, MediaUtils.BackgroundFetchThumbnail.TYPE_VIDEO);
                            imageView.getViewTreeObserver().removeOnPreDrawListener(this);
                            return true;
                        }
                    });
                } else {
                    MediaUtils.fadeMediaItemImageIntoView(imageSource, cache, imageView, mediaItem,
                            width, height, MediaUtils.BackgroundFetchThumbnail.TYPE_VIDEO);
                }
            }
        }

        return convertView;
    }

    /**
     * {@link android.os.Parcelable} interface
     */

    public static final Creator<MediaSourceDeviceVideos> CREATOR =
            new Creator<MediaSourceDeviceVideos>() {
                public MediaSourceDeviceVideos createFromParcel(Parcel in) {
                    List<MediaItem> parcelData = new ArrayList<>();
                    in.readTypedList(parcelData, MediaItem.CREATOR);
                    MediaSourceDeviceVideos newItem = new MediaSourceDeviceVideos();

                    if (parcelData.size() > 0) {
                        newItem.setMediaItems(parcelData);
                    }

                    return newItem;
                }

                public MediaSourceDeviceVideos[] newArray(int size) {
                    return new MediaSourceDeviceVideos[size];
                }
            };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeTypedList(mMediaItems);
    }
}
