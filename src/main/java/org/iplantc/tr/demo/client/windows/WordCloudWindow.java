package org.iplantc.tr.demo.client.windows;

import com.extjs.gxt.ui.client.Style.Scroll;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.event.WindowEvent;
import com.extjs.gxt.ui.client.widget.Html;
import com.extjs.gxt.ui.client.widget.Window;

public class WordCloudWindow extends Window
{
	private Html panel;

	private static WordCloudWindow instance;

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

	public void setContents(String html, String geneFamily)
	{
		panel.setHtml(html);
		setHeading("GO terms for " + geneFamily);
	}
	
	private void compose()
	{
		add(panel);
	}
}
