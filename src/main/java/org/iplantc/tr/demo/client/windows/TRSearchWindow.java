package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.commands.ViewTRResultCommand;
import org.iplantc.tr.demo.client.panels.TRAdvancedSearchPanel;
import org.iplantc.tr.demo.client.services.SearchService;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;

import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;
import com.google.gwt.core.client.GWT;

public class TRSearchWindow extends Window
{
	private final SearchServiceAsync searchService = GWT.create(SearchService.class);

	private static TRSearchWindow instance;

	private TRSearchWindow()
	{
		init();

		compose();
	}

	private void init()
	{
		setLayout(new FitLayout());
		setHeading("Search");
		setSize(419, 243);
		setResizable(false);
	}

	private void compose()
	{
		removeAll();

		add(new TRAdvancedSearchPanel(searchService, new ViewTRResultCommand()));

		layout();
	}

	public static TRSearchWindow getInstance()
	{
		if(instance == null)
		{
			instance = new TRSearchWindow();
		}

		return instance;
	}
}
