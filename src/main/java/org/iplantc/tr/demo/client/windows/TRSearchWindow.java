package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.commands.ClientCommand;
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
		
		add(new TRAdvancedSearchPanel(searchService, new ViewCommand()));
		
		layout();
	}
	
	private void doView(final String params)
	{
		if(params != null)
		{
			TRViewerWindow  win = new TRViewerWindow(params);
			win.show();
			win.maximize();
		}
	}
	
	public static TRSearchWindow getInstance()
	{
		if(instance == null)
		{
			instance = new TRSearchWindow();
		}
		
		return instance;
	}
		
	class ViewCommand implements ClientCommand
	{
		@Override
		public void execute(final String params)
		{
			doView(params);
		}
	}
}
