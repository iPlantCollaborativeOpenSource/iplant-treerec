package org.iplantc.tr.demo.client;

import com.extjs.gxt.ui.client.Style.HorizontalAlignment;
import com.extjs.gxt.ui.client.Style.Scroll;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.layout.TableData;
import com.google.gwt.core.client.GWT;
import com.google.gwt.user.client.Element;

public class TRAdvancedSearchPanel extends ContentPanel
{
	private VerticalPanel pnlInner;
	private TableData tableData;
	
	private final SearchServiceAsync searchService = GWT.create(SearchService.class);
	
	public TRAdvancedSearchPanel()
	{
		init();
	}

	private void init()
	{			
		setHeaderVisible(false);
		initInnerPanel();
		setScrollMode(Scroll.AUTO);
	}

	private void initInnerPanel()
	{
		pnlInner = new VerticalPanel();
		pnlInner.setSpacing(10);
		pnlInner.setStyleAttribute("background-color", "white");		
	}
	
	private void initTableData()
	{
		tableData = new TableData();		
		tableData.setWidth(Integer.toString(getWidth()));
		tableData.setHorizontalAlign(HorizontalAlignment.CENTER);
	}
	
	private void doView(final String params)
	{
		if(params != null)
		{
			TRViewerWindow  win = new TRViewerWindow(searchService, params);
			win.show();
			win.maximize();
		}
	}
	
	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void onRender(Element parent, int index)
	{
		super.onRender(parent, index);
			
		initTableData();
	    
		pnlInner.add(new TRToolPanel(searchService, new ViewCommand(), new SearchBeginCommand(), new SearchCompleteCommand()), tableData);
			
		add(pnlInner);		
	}
	
	class ViewCommand implements ClientCommand
	{
		@Override
		public void execute(final String params)
		{
			doView(params);
		}
	}
	
	class SearchBeginCommand implements ClientCommand
	{
		@Override
		public void execute(final String params)
		{
			mask("Working...");
		}
	}
	
	class SearchCompleteCommand implements ClientCommand
	{
		@Override
		public void execute(final String params)
		{
			unmask();
		}
	}
}

