package org.iplantc.tr.demo.client;


import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.LayoutContainer;
import com.extjs.gxt.ui.client.widget.TabItem;
import com.extjs.gxt.ui.client.widget.TabPanel;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONParser;
import com.google.gwt.user.client.Element;
import com.google.gwt.user.client.rpc.AsyncCallback;



public class TRViewerPanel extends ContentPanel
{
	private TabPanel pnlInner;
	private SearchServiceAsync searchService;
	
	public TRViewerPanel(final SearchServiceAsync searchService,final String idGene)
	{
		this.searchService = searchService;
		
		init(idGene);

		retrieveData(idGene);
	}

	private void init(final String caption)
	{
		setHeading("Gene Cluster:" + caption);
		
		initTabs();
		setSize(920, 600);	
		setLayout(new FitLayout());		
	}

	private void initTabs()
	{
		pnlInner = new TabPanel();

		pnlInner.setMinTabWidth(55);
		pnlInner.setResizeTabs(true);
		pnlInner.setAnimScroll(true);
		pnlInner.setTabScroll(true);		
	}

	private void addTab(int idx, String caption, LayoutContainer container)
	{
		if(container != null)
		{
			TabItem item = new TabItem(caption);

			item.add(container);

			// if this is our first item or it is slotted past items we don't have yet,
			// simply add the tab
			if(idx < 0 || idx > pnlInner.getItems().size())
			{
				pnlInner.add(item);
			}
			else
			{
				pnlInner.insert(item, idx);
			}

			// make sure we only select the first tab
			pnlInner.setSelection(pnlInner.getItem(0));
		}
	}

	private String getURL(final JSONObject jsonObj, final String key)
	{
		String ret = null; // assume failure

		if(jsonObj != null && key != null)
		{
			if(jsonObj.containsKey("relativeUrls"))
			{
				JSONObject jsonUrl = (JSONObject)jsonObj.get("relativeUrls");

				if(jsonUrl != null)
				{
					if(jsonUrl.containsKey(key))
					{
						ret = "http://gargery.iplantcollaborative.org/treereconciliation/"
								+ jsonUrl.get(key).isString().stringValue();
					}
				}
			}
		}

		return ret;
	}

	private void retrieveGeneTree(final JSONObject jsonObj)
	{
		String urlDisplay = getURL(jsonObj, "getGeneTreeImage");
		String urlDownload = getURL(jsonObj, "downloadGeneTreeImage");

		if(urlDisplay != null && urlDownload != null)
		{
			DownloadableImageViewPanel pnl = new DownloadableImageViewPanel(urlDisplay, urlDownload);
						
			addTab(1, "Gene Tree", pnl);
		}
	}

	private void retrieveSpeciesTree(final JSONObject jsonObj)
	{
		String urlDisplay = getURL(jsonObj, "getSpeciesTreeImage");
		String urlDownload = getURL(jsonObj, "downloadSpeciesTreeImage");

		if(urlDisplay != null && urlDownload != null)
		{
			DownloadableImageViewPanel pnl = new DownloadableImageViewPanel(urlDisplay, urlDownload);
			
			addTab(2, "Species Tree", pnl);
		}
	}

	private void retrieveReconciledTree(final JSONObject jsonObj)
	{
		String urlDisplay = getURL(jsonObj, "getFatTreeImage");
		String urlDownload = getURL(jsonObj, "downloadFatTreeImage");

		if(urlDisplay != null && urlDownload != null)
		{
			DownloadableImageViewPanel pnl = new DownloadableImageViewPanel(urlDisplay, urlDownload);
						
			addTab(0, "Reconciliation", pnl);
		}
	}

	private void buildDetailsTab(final JSONObject jsonObj)
	{
		TRDetailsPanel pnl = new TRDetailsPanel(jsonObj);
		
		addTab(3, "Details", pnl);
	}
	
	private void retrieveData(final String idGeneFamily)
	{
		// if we don't have a gene id, there's no use trying to retrieve data.
		if(idGeneFamily != null)
		{
			searchService.getDetails(idGeneFamily, new AsyncCallback<String>()
			{
				@Override
				public void onFailure(Throwable arg0)
				{
					// do nothing... for now.				
				}

				@Override
				public void onSuccess(String result)
				{
					JSONObject jsonObj = (JSONObject)JSONParser.parse(result);

					//drill down from the extra wrapping perl provides
					if(jsonObj != null)
					{
						//drill past data
						jsonObj = (JSONObject)jsonObj.get("data");
						
						if(jsonObj != null)
						{
							//drill past item
							jsonObj = (JSONObject)jsonObj.get("item");
							
							//now we should be at the level we need
							if(jsonObj != null)
							{
								retrieveGeneTree(jsonObj);
								retrieveSpeciesTree(jsonObj);
								retrieveReconciledTree(jsonObj);
								buildDetailsTab(jsonObj);		
							}
						}						
					}
				}
			});
		}
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void onRender(Element parent, int index)
	{
		super.onRender(parent, index);

		add(pnlInner);
	}
}
