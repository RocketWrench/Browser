package web;

import org.cef.browser.CefBrowser;
import org.cef.browser.CefFrame;
import org.cef.handler.CefLifeSpanHandlerAdapter;
import com.mathworks.jmi.Callback;
import javax.swing.SwingUtilities;
import java.awt.Dimension;

public class LifeSpanHandler extends CefLifeSpanHandlerAdapter {

  private final Callback callback_ = new Callback();

  @Override
  public boolean onBeforePopup(CefBrowser browser,
                               CefFrame frame,
                               String target_url,
                               String target_frame_name) {
 
    if (!target_url.isEmpty()){
        browser.loadURL(target_url);
    }
    this.callback_.postCallback(new BrowserEventData(browser,frame,target_url,target_frame_name));    
    return true;
  }

  @Override
  public void onAfterCreated(CefBrowser browser, int identifier) {
    SwingUtilities.invokeLater(() -> {
        Dimension dimension = browser.getUIComponent().getSize();
        if (dimension.getWidth() > 0.0D && dimension.getHeight() > 0.0D)
            browser.getUIComponent().setSize(dimension);
    });

    this.callback_.postCallback(new BrowserEventData(browser,identifier));
  }
  
  @Override
  public void onAfterParentChanged(CefBrowser browser) {
      
    this.callback_.postCallback(new BrowserEventData(browser));
  }

  @Override
  public boolean doClose(CefBrowser browser) {
    return true;
  }

  @Override
  public void onBeforeClose(CefBrowser browser) {
  }
  
  public Callback getCallback(){
      
     return this.callback_;
  }

}