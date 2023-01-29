package web;

import org.cef.handler.CefLoadHandlerAdapter;
import org.cef.handler.CefLoadHandler;
import org.cef.browser.CefBrowser;
import org.cef.browser.CefFrame;
import org.cef.network.CefRequest;
import com.mathworks.jmi.Callback;
import web.ui.BrowserPanel;
        
public class LoadHandler extends CefLoadHandlerAdapter{
    private final Callback callback_ = new Callback();

    @Override
    public void onLoadingStateChange(CefBrowser browser,
                                     boolean isLoading,
                                     boolean canGoBack,
                                     boolean canGoForward){
        if (browser.getUIComponent().getParent() != null){
            if (browser.getUIComponent().getParent().getName().equalsIgnoreCase("BrowserPanel")){
                BrowserPanel parent = (BrowserPanel) browser.getUIComponent().getParent();
                if (parent.hasAddressPane()){
                    parent.update(browser, isLoading, canGoBack, canGoForward);
                    System.out.println("OnLoadingStateChange");
                }
            }
        }
        this.callback_.postCallback(new BrowserEventData(browser,isLoading,canGoBack,canGoForward));
    }
    
    @Override
    public void onLoadStart(CefBrowser browser,
                            CefFrame frame,
                            CefRequest.TransitionType transitionType){

        this.callback_.postCallback(new BrowserEventData(browser,frame,transitionType));
    }
    
    @Override
    public void onLoadEnd(CefBrowser browser,
                          CefFrame frame,
                          int httpStatusCode){

        this.callback_.postCallback(new BrowserEventData(browser,frame,httpStatusCode));
    }
    
    @Override
    public void onLoadError(CefBrowser browser,
                            CefFrame frame,
                            CefLoadHandler.ErrorCode errorCode,
                            String errorText,
                            String failedUrl){

        this.callback_.postCallback(new BrowserEventData(browser,frame,errorCode,errorText,failedUrl));
    }
    
    public Callback getCallback(){
        
        return this.callback_;
    }

}