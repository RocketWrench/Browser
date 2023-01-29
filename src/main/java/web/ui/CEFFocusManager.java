package web.ui;

import com.mathworks.util.PlatformInfo;
import java.awt.Component;
import java.awt.KeyboardFocusManager;
import java.awt.event.ActionEvent;
import java.awt.event.FocusEvent;
import java.awt.event.FocusListener;
import javax.swing.JComponent;
import javax.swing.SwingUtilities;
import javax.swing.Timer;
import org.cef.OS;
import org.cef.browser.CefBrowser;

class CEFFocusManager implements FocusListener {
  private final CefBrowser browser_;
  
  private CEFFocusManager(CefBrowser paramCefBrowser) {
    this.browser_ = paramCefBrowser;
  }
  
  static CEFFocusManager install(CefBrowser browser) {
    CEFFocusManager focusManager = new CEFFocusManager(browser);
    installCustomFocusListeners(browser, focusManager);
    return focusManager;
  }
  
  static void uninstall(CefBrowser browser, CEFFocusManager focusManager) {
    browser.getUIComponent().removeFocusListener(focusManager);
  }
  
  private static void installCustomFocusListeners(CefBrowser browser, CEFFocusManager focusManager) {
    Component component = browser.getUIComponent();
    for (FocusListener focusListener : component.getFocusListeners())
      component.removeFocusListener(focusListener); 
    component.addFocusListener(focusManager);
  }
  
  private boolean isBrowserComponent(Component component) {
    if (component == null)
      return false; 
    return component.getClass().getName().contains("org.cef.browser.CefBrowser");
  }
  
  private boolean isFocusOwner(Component component) {
    if (component == null)
      return false; 
    return component.equals(KeyboardFocusManager.getCurrentKeyboardFocusManager().getFocusOwner());
  }
  
  private void removeOppositeBrowserFocus(Component component) {
    if (isBrowserComponent(component)) {
      CefBrowser browser = (CefBrowser)((JComponent)component.getParent()).getClientProperty("CefBrowser");
      if (browser != null && 
        this.browser_.getIdentifier() != browser.getIdentifier())
        browser.setFocus(false); 
    } 
  }
  
  private boolean isTemporaryFocusEvent(FocusEvent event) {
    if (OS.isLinux())
      return false; 
    return (event.isTemporary() || isTemporaryFocusOwnerComponent(event.getOppositeComponent()));
  }
  
  private void setFocusOnBrowserAndInvalidate() {
    Component component = this.browser_.getUIComponent();
    if (component != null && isFocusOwner(component)) {
      if (!this.browser_.isFocusable())
        this.browser_.setFocusable(true); 
      this.browser_.setFocus(true);
      component.invalidate();
    } 
  }
  
  @Override
  public synchronized void focusGained(FocusEvent event) {
    if (isTemporaryFocusEvent(event))
      return; 
    if (OS.isLinux())
      removeOppositeBrowserFocus(event.getOppositeComponent()); 
    if (PlatformInfo.isWindows()) {
      Timer timer = new Timer(200, (ActionEvent param1ActionEvent) -> {
          CEFFocusManager.this.setFocusOnBrowserAndInvalidate();
      });
      timer.setRepeats(false);
      timer.start();
    } else {
      setFocusOnBrowserAndInvalidate();
    } 
    boolean bool = PlatformInfo.isMacintosh();
    if (bool)
      SwingUtilities.invokeLater(() -> {
          CEFFocusManager.this.browser_.getUIComponent().repaint();
    }); 
  }
  
  private boolean isOnIgnoreReleaseFocusList(Component component) {
    if (null == component)
      return false; 
    String str = component.getClass().getName();
    return (str.contains("com.mathworks.widgets.desk.DTTiledPane") || str
      .contains("com.mathworks.widgets.desk.DTRootPane") || str
      .contains("com.mathworks.widgets.desk.DTMaximizedPane"));
  }
  
  private boolean shouldReleaseFocus(Component component) {
    return (null != component && component
      .isFocusable() && 
      !isOnIgnoreReleaseFocusList(component));
  }
  
  @Override
  public synchronized void focusLost(FocusEvent event) {
    if (isTemporaryFocusEvent(event))
      return; 
    if ((OS.isWindows() || OS.isMacintosh()) && !shouldReleaseFocus(event.getOppositeComponent()))
      return; 
    this.browser_.setFocus(false);
    this.browser_.setFocusable(false);
    if (!OS.isLinux() && 
      !isBrowserComponent(event.getOppositeComponent())) {
      KeyboardFocusManager.getCurrentKeyboardFocusManager().clearGlobalFocusOwner();
      Runnable runnable = () -> {
          Component component = KeyboardFocusManager.getCurrentKeyboardFocusManager().getFocusOwner();
          if (component != null)
              component.requestFocusInWindow();
      };
      SwingUtilities.invokeLater(runnable);
    } 
  }
  
  private boolean isTemporaryFocusOwnerComponent(Component component) {
    if (component instanceof JComponent) {
      JComponent jComponent = (JComponent)component;
      Object object = jComponent.getClientProperty("temporary-focus-owner");
      if (object != null)
        return ((Boolean)object); 
    } 
    return false;
  }
}
