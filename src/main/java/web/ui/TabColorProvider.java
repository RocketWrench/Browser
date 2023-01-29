package web.ui;

import com.jidesoft.swing.JideTabbedPane;
import com.jidesoft.swing.JideTabbedPane.ColorProvider;
import javax.swing.UIManager;
//import com.jidesoft.plaf.UIDefaultsLookup;
import java.awt.Color;

public class TabColorProvider implements ColorProvider{
    private final JideTabbedPane tabbedPane_ ;
    private final Color background_ = UIManager.getColor ( "Panel.background" );//UIDefaultsLookup.getColor("JideTabbedPane.tabAreaBackground");
    
    public TabColorProvider( JideTabbedPane tabbedPane ) {
        tabbedPane_ = tabbedPane;}
    
    //public TabColorProvider() {} 

    @Override
    public Color getBackgroundAt(int index) {
         
        int n = tabbedPane_.getTabCount();
        if ( n > 1 ){
            for(int i = 0; i < n; ++i){
                //if (i != index){
                    tabbedPane_.setBackgroundAt(i, null);
                    tabbedPane_.revalidate();
                //}
            }
        }
        return Color.WHITE; 
    }

    @Override
    public Color getForegroundAt(int index) {
        return Color.BLACK;
    }

    @Override
    public float getGradientRatio(int index) {
        return 1;
    }
    
    public Color getBackground(){
        return background_;
    }    
}
