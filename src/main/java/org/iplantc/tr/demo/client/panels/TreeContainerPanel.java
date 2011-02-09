package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;
import java.util.List;

import org.iplantc.tr.demo.client.EventBusContainer;
import org.iplantc.tr.demo.client.Hyperlink;
import org.iplantc.tr.demo.client.receivers.GeneTreeInvestigationModeReceiver;
import org.iplantc.tr.demo.client.receivers.GeneTreeNavModeReceiver;
import org.iplantc.tr.demo.client.receivers.Receiver;
import org.iplantc.tr.demo.client.receivers.SpeciesTreeInvestigationModeReceiver;
import org.iplantc.tr.demo.client.receivers.SpeciesTreeNavModeReceiver;
import org.iplantc.tr.demo.client.services.SearchService;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;
import org.iplantc.tr.demo.client.utils.PanelHelper;
import org.iplantc.tr.demo.client.utils.TRUtil;
import org.iplantc.tr.demo.client.utils.TreeRetriever;
import org.iplantc.tr.demo.client.utils.TreeRetrieverCallBack;
import org.iplantc.tr.demo.client.windows.SupportingDataWindow;

import com.extjs.gxt.ui.client.Style.Scroll;
import com.extjs.gxt.ui.client.event.BaseEvent;
import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.widget.Component;
import com.extjs.gxt.ui.client.widget.HorizontalPanel;
import com.extjs.gxt.ui.client.widget.LayoutContainer;
import com.extjs.gxt.ui.client.widget.button.ToggleButton;
import com.extjs.gxt.ui.client.widget.toolbar.FillToolItem;
import com.extjs.gxt.ui.client.widget.toolbar.ToolBar;
import com.google.gwt.core.client.GWT;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.rpc.AsyncCallback;

public class TreeContainerPanel extends EventBusContainer
{
	private ToggleButton btnNav;
	private ToggleButton btnSelect;

	private List<TreeChannelPanel> treePanels;

	private List<Receiver> receiversNav;
	private List<Receiver> receiversSelect;

	private TreeRetriever treeRetriever;

	private HorizontalPanel pnlOuter;

	private String idGeneFamily;

	private final SearchServiceAsync searchService = GWT.create(SearchService.class);

	enum Mode
	{
		NAVIGATE, INVESTIGATION
	}

	public TreeContainerPanel(String idGeneFamily)
	{
		this.idGeneFamily = idGeneFamily;

		treePanels = new ArrayList<TreeChannelPanel>();
		receiversNav = new ArrayList<Receiver>();
		receiversSelect = new ArrayList<Receiver>();

		treeRetriever = new TreeRetriever();

		setScrollMode(Scroll.AUTO);

		compose();
	}

	private void addSpeciesTreePanel(LayoutContainer containerOuter, TreeChannelPanel pnl)
	{
		SpeciesTreeNavModeReceiver receiverNav = new SpeciesTreeNavModeReceiver(eventbus, pnl.getId());
		SpeciesTreeInvestigationModeReceiver receiverSelect =
				new SpeciesTreeInvestigationModeReceiver(eventbus, pnl.getId());

		addBroadcaster(pnl.getBroadcaster(), receiverNav, buildBroadcastCommand(pnl.getId()));
		addBroadcaster(pnl.getBroadcaster(), receiverSelect, buildBroadcastCommand(pnl.getId()));

		receiversNav.add(receiverNav);
		receiversSelect.add(receiverSelect);

		treePanels.add(pnl);

		containerOuter.add(pnl);

		layout();
	}

	private void addGeneTreePanel(LayoutContainer containerOuter, TreeChannelPanel pnl)
	{
		GeneTreeNavModeReceiver receiverNav = new GeneTreeNavModeReceiver(eventbus, pnl.getId());
		GeneTreeInvestigationModeReceiver receiverSelect =
				new GeneTreeInvestigationModeReceiver(eventbus, pnl.getId());

		addBroadcaster(pnl.getBroadcaster(), receiverNav, buildBroadcastCommand(pnl.getId()));
		addBroadcaster(pnl.getBroadcaster(), receiverSelect, buildBroadcastCommand(pnl.getId()));

		receiversNav.add(receiverNav);
		receiversSelect.add(receiverSelect);

		treePanels.add(pnl);

		containerOuter.add(pnl);
		layout();
	}

	private void buildNavButton()
	{
		btnNav =
				PanelHelper.buildToggleButton("idNavBtn", "Navigate",
						new SelectionListener<ButtonEvent>()
						{
							@Override
							public void componentSelected(ButtonEvent ce)
							{
								if(btnSelect != null)
								{
									btnSelect.toggle(false);
									toggleMode(Mode.NAVIGATE);
								}
							}
						});

		btnNav.toggle(true);
	}

	private void buildSelectButton()
	{
		btnSelect =
				PanelHelper.buildToggleButton("idInvestigationBtn", "Investigation",
						new SelectionListener<ButtonEvent>()
						{
							@Override
							public void componentSelected(ButtonEvent ce)
							{
								if(btnNav != null)
								{
									btnNav.toggle(false);
									toggleMode(Mode.INVESTIGATION);
								}
							}
						});
	}

	private Hyperlink buildSummaryLink()
	{
		Hyperlink link = new Hyperlink("Get supporting data for this reconciliation");

		link.setStyleAttribute("margin-top", "15px");
		link.setHeight(18);

		link.addListener(Events.OnClick, new Listener<BaseEvent>()
		{

			@Override
			public void handleEvent(BaseEvent be)
			{
				showSummaryWindow();
			}
		});

		return link;
	}

	private void showSummaryWindow()
	{
		searchService.getDetails(idGeneFamily, new AsyncCallback<String>()
		{
			@Override
			public void onFailure(Throwable arg0)
			{
				arg0.printStackTrace();
				// do nothing... for now.
			}

			@Override
			public void onSuccess(String result)
			{
				JSONValue dataItem = TRUtil.parseItem(result);

				if(dataItem != null)
				{
					JSONObject jsonObj = dataItem.isObject();
					if(jsonObj != null)
					{
						showDetails(jsonObj);
					}
				}
			}
		});
	}

	private void showDetails(final JSONObject jsonObj)
	{
		TRDetailsPanel pnl = new TRDetailsPanel(idGeneFamily, jsonObj);

		new SupportingDataWindow(pnl, idGeneFamily).show();
	}

	private Component buildToolbar()
	{
		ToolBar ret = new ToolBar();

		buildNavButton();
		buildSelectButton();

		ret.add(btnNav);
		ret.add(btnSelect);
		ret.add(new FillToolItem());

		ret.add(buildSummaryLink());

		return ret;
	}

	private void toggleReceivers(final List<Receiver> enable, final List<Receiver> disable)
	{
		for(Receiver receiver : enable)
		{
			receiver.enable();
		}

		for(Receiver receiver : disable)
		{
			receiver.disable();
		}
	}

	private void toggleMode(Mode mode)
	{
		if(mode == Mode.NAVIGATE)
		{
			toggleReceivers(receiversNav, receiversSelect);
		}
		else
		{
			toggleReceivers(receiversSelect, receiversNav);
		}
	}

	private void compose()
	{
		// add our button bar
		setTopComponent(buildToolbar());

		// gratuitous outer panel for spacing
		pnlOuter = new HorizontalPanel();
		pnlOuter.setSpacing(10);

		treeRetriever.getSpeciesTree(idGeneFamily, new SpeciesTreeRetrieverCallBack());

		// show
		add(pnlOuter);
	}

	public void cleanup()
	{
		for(TreeChannelPanel pnl : treePanels)
		{
			pnl.cleanup();
		}

		treePanels.clear();
	}

	private class SpeciesTreeRetrieverCallBack extends TreeRetrieverCallBack
	{
		@Override
		public void execute()
		{
			addSpeciesTreePanel(pnlOuter, new SpeciesTreeChannelPanel(eventbus, "Species Tree",
					"idSpeciesTree", getTree(), getLayout(), idGeneFamily));
			treeRetriever.getGeneTree(idGeneFamily, new GeneTreeRetrieverCallBack());
		}
	}

	private class GeneTreeRetrieverCallBack extends TreeRetrieverCallBack
	{
		@Override
		public void execute()
		{
			addGeneTreePanel(pnlOuter, new GeneTreeChannelPanel(eventbus, "Gene Tree", "idGeneTree",
					getTree(), getLayout(), idGeneFamily));
			// set our default mode
			toggleMode(Mode.NAVIGATE);
		}
	}
}
