/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package web;

import org.cef.browser.CefBrowser;
import org.cef.callback.CefBeforeDownloadCallback;
import org.cef.callback.CefDownloadItem;
import org.cef.callback.CefDownloadItemCallback;
import org.cef.handler.CefDownloadHandlerAdapter;
import com.mathworks.jmi.Callback;

public class DownloadHandler extends CefDownloadHandlerAdapter {
    
    private final Callback callback_ = new Callback();
    
    @Override
    public void onBeforeDownload(CefBrowser browser, CefDownloadItem downloadItem,
            String suggestedName, CefBeforeDownloadCallback callback) {
        
        if (downloadItem.isValid()){
            if (downloadItem.getMimeType().contains("image")){
                String URL = downloadItem.getURL();
                if (!URL.contains("webp")){
                    this.callback_.postCallback(new BrowserEventData(suggestedName,URL));
                }
                else{
                     callback.Continue(suggestedName,true);
                }
            }
            else{
                callback.Continue(suggestedName,true);
            }
        }
    }

    @Override
    public void onDownloadUpdated(
            CefBrowser browser, CefDownloadItem downloadItem, CefDownloadItemCallback callback) {
    }
    
    public Callback getCallback(){
        
        return this.callback_;
    }
}
