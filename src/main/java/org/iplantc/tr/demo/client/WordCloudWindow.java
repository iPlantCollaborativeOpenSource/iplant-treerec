package org.iplantc.tr.demo.client;

import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.Window;

public class WordCloudWindow extends Window
{

	public WordCloudWindow() {
		init();
	}
	
	private void init() {
		setHeading("GO terms");
		ContentPanel panel = new ContentPanel();
		panel.setStyleName("wordCloud");
		panel.setHeaderVisible(false);
		add(panel);
		setSize(483, 310);
	}
}
