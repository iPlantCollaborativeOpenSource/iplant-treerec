package org.iplantc.tr.demo.client.windows;

import org.iplantc.tr.demo.client.commands.ClientCommand;
import org.iplantc.tr.demo.client.panels.TRToolPanel;
import org.iplantc.tr.demo.client.services.SearchService;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;

import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;
import com.google.gwt.core.client.GWT;

public class TRSearchWindow extends Window
{
	private final SearchServiceAsync searchService = GWT.create(SearchService.class);

	public TRSearchWindow() 
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
		add(new TRToolPanel(searchService, new ViewCommand()));
	}
	
	private void doView(final String params)
	{
		if(params != null)
		{
			TRViewerWindow  win = new TRViewerWindow(null, params);
			win.show();
			win.maximize();
		}
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
