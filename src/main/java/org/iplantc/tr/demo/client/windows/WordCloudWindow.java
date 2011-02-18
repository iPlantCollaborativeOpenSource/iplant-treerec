package org.iplantc.tr.demo.client.windows;

import com.extjs.gxt.ui.client.Style.Scroll;
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
			instance.init();
		}

		return instance;
	}

	private void init()
	{
		removeAll();
		panel = new Html();
		setSize(500, 460);
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
