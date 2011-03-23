package org.iplantc.tr.demo.client.windows;



import com.extjs.gxt.ui.client.Style;
import com.extjs.gxt.ui.client.Style.LayoutRegion;
import com.extjs.gxt.ui.client.Style.Orientation;
import com.extjs.gxt.ui.client.Style.Scroll;
import com.extjs.gxt.ui.client.core.El;
import com.extjs.gxt.ui.client.event.ComponentEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.event.WindowEvent;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.Html;
import com.extjs.gxt.ui.client.widget.ScrollContainer;
import com.extjs.gxt.ui.client.widget.SplitBar;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.Viewport;
import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.RowData;
import com.extjs.gxt.ui.client.widget.layout.RowLayout;
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.user.client.ui.Label;
import com.google.gwt.user.client.ui.ScrollPanel;
import com.google.gwt.user.client.ui.VerticalSplitPanel;

public class WordCloudWindow extends Window
{
	private Html panel;
	private LegendWindow legend;
	private static WordCloudWindow instance;
	private ScrollContainer<Html> scontainer;
	
	public static WordCloudWindow getInstance()
	{
		if(instance == null)
		{
			instance = new WordCloudWindow();
		}
		instance.hide();
		return instance;
	}

	private WordCloudWindow() {
		init();
	}
	
	private void init()
	{
		addListener(Events.Show, new Listener<WindowEvent>() {

			@Override
			public void handleEvent(WindowEvent be)
			{
				setSize(500, 460);
			}
		});
		
		 
		   
		
		
		panel = new Html();
		
		setScrollMode(Scroll.AUTO);
		compose();
	}

	public void setContents(String html, String geneFamily,final String terms)
	{
		
		panel.setHtml(html.replace("\\", ""));
		System.out.println(html);
		setHeading("GO terms for " + geneFamily);
		
		
		
		addListener(Events.Hide, new Listener<ComponentEvent>() {
			@Override
			public void handleEvent(ComponentEvent be) {
				// TODO Auto-generated method stub
				legend.hide();
			}
		});
		
	}
	
	private void compose()
	{
		 VerticalPanel vpanel = new VerticalPanel();
		 
		 VerticalPanel cpanel = new VerticalPanel();
		 Html legend = new Html("<span class=\"biological_process\"><span class=\"tagcloud3\">&#x25a0;Biological Process" +
		 		"</span></span><br/><span class=\"cellular_component\"><span class=\"tagcloud3\">&#x25a0;Cellular Component" +
		 		"</span></span><br/><div class=\"molecular_function\"><span class=\"tagcloud3\">&#x25a0;Molecular Function" +
		 		"</span></div><br/>");
		 cpanel.add(legend);
		 cpanel.setBorders(true);
		 
		 cpanel.setHeight(100);
		 vpanel.add(cpanel);
		 vpanel.add(panel);
		 
		add(vpanel);
	}
	
	
	class LegendWindow extends Window {
		
		private String categories;
		
		public LegendWindow(String cats) {
			categories =cats;
			setHeading("GO Categories");
			init();
			
			compose();
		}
		
		
		
		private void init() {
			setSize(200,200);
		}
		
		
		private void compose() {
			VerticalPanel panel = new VerticalPanel();
			
			String[] cats = categories.replace("[", "").replace("]", "").replace("\"", "").split(",");
			
			for(int i=0; i < cats.length; i++) {
				Html html = new Html("<span class=\""+cats[i]+"\" > &#9723; "+cats[i].replace("_", " ")+"</span>");
				
				panel.add(html);
			}
			
			
			add(panel);
		}
		
	}
	
}
