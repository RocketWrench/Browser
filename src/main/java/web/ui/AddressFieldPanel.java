package web.ui;

import com.jidesoft.swing.JideBoxLayout;
import java.awt.BasicStroke;
//import java.awt.BorderLayout;
import java.awt.Color;
//import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.RoundRectangle2D;
//import javax.swing.BoxLayout;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.border.EmptyBorder;
import javax.swing.Box;

public class AddressFieldPanel extends JPanel {

    private final JTextField field;
        private final RenderingHints hints = new RenderingHints(RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON);
        //RenderingHints.KEY_ANTIALIASING,RenderingHints.VALUE_ANTIALIAS_ON
        //RenderingHints.KEY_STROKE_CONTROL,RenderingHints.VALUE_STROKE_NORMALIZE
        private static final Color FOCUS_COLOR = new Color(30,136,229);
    public AddressFieldPanel(JTextField field) {
        this.field = field;
        setBorder(new EmptyBorder(2, 2, 2, 2));
        field.setBorder(new EmptyBorder(2, 10, 2, 10));
        setLayout(new JideBoxLayout(this,JideBoxLayout.X_AXIS));
        //setPreferredSize(new Dimension(100,28));
        add(Box.createHorizontalStrut(14));
        add(field,JideBoxLayout.VARY);
        add(Box.createHorizontalStrut(14));
        setOpaque(false);
    }

    @Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        Graphics2D g2d = (Graphics2D) g.create();
        g2d.setRenderingHints(hints);
        float width = getWidth() -1;
        float height = getHeight() -1;
        float arch = (float) (height * 1);
        RoundRectangle2D shape = new RoundRectangle2D.Float(0, 0, width, height, arch, arch);
        g2d.setColor(field.getBackground());
        g2d.fill(shape);
        if (field.hasFocus()){
            g2d.setStroke(new BasicStroke(2));
            g2d.setColor(FOCUS_COLOR);
            g2d.draw(shape);
        }
        g2d.dispose();
    }

}
