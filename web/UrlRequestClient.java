package web;

import org.cef.callback.CefAuthCallback;
import org.cef.callback.CefURLRequestClient;
import org.cef.network.CefURLRequest;
import com.mathworks.jmi.Callback;

public class UrlRequestClient implements CefURLRequestClient {
    
    private final Callback callback_ = new Callback();

    @Override
    public void onRequestComplete(CefURLRequest request) {
        this.callback_.postCallback(new UrlRequestEventData(request));
    }

    @Override
    public void onUploadProgress(CefURLRequest request, int current, int total) {
        this.callback_.postCallback(new UrlRequestEventData(UrlRequestType.UPLOAD_PROGRESS,request,current,total));
    }

    @Override
    public void onDownloadProgress(CefURLRequest request, int current, int total) {
        this.callback_.postCallback(new UrlRequestEventData(UrlRequestType.DOWNLOAD_PROGRESS,request,current,total));
    }

    @Override
    public void onDownloadData(CefURLRequest request, byte[] bytes, int length) {
        this.callback_.postCallback(new UrlRequestEventData(request,bytes,length));
    }

    @Override
    public boolean getAuthCredentials(boolean bln, String string, int i, String string1, String string2, CefAuthCallback cac) {
        return false;
    }

    @Override
    public void setNativeRef(String string, long l) {
        
    }

    @Override
    public long getNativeRef(String string) {
        throw new UnsupportedOperationException("Not supported yet."); // Generated from nbfs://nbhost/SystemFileSystem/Templates/Classes/Code/GeneratedMethodBody
    }
    
    public Callback getCallback(){        
        return this.callback_;
    }    
    
}
