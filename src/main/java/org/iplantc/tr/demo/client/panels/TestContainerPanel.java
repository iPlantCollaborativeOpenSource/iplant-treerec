package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;
import java.util.List;

import org.iplantc.tr.demo.client.EventBusContainer;
import org.iplantc.tr.demo.client.receivers.GeneTreeInvestigationModeReceiver;
import org.iplantc.tr.demo.client.receivers.GeneTreeNavModeReceiver;
import org.iplantc.tr.demo.client.receivers.Receiver;
import org.iplantc.tr.demo.client.receivers.SpeciesTreeInvestigationModeReceiver;
import org.iplantc.tr.demo.client.receivers.SpeciesTreeNavModeReceiver;
import org.iplantc.tr.demo.client.utils.PanelHelper;
import org.iplantc.tr.demo.client.utils.TreeRetriever;
import org.iplantc.tr.demo.client.utils.TreeRetrieverCallBack;

import com.extjs.gxt.ui.client.Style.HorizontalAlignment;
import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.widget.HorizontalPanel;
import com.extjs.gxt.ui.client.widget.LayoutContainer;
import com.extjs.gxt.ui.client.widget.button.ToggleButton;
import com.extjs.gxt.ui.client.widget.toolbar.ToolBar;

public class TestContainerPanel extends EventBusContainer
{
	private ToggleButton btnNav;
	private ToggleButton btnSelect;

	List<Receiver> receiversNav;
	List<Receiver> receiversSelect;
	
	TreeRetriever treeRetriever;
	
	
	HorizontalPanel pnlOuter;
	
	enum Mode
	{
		NAVIGATE, INVESTIGATION
	}

	public TestContainerPanel()
	{
		receiversNav = new ArrayList<Receiver>();
		receiversSelect = new ArrayList<Receiver>();

		treeRetriever = new TreeRetriever();
		compose();
	}

	private void addSpeciesTreePanel(LayoutContainer containerOuter, TreeChannelPanel pnl)
	{
		SpeciesTreeNavModeReceiver receiverNav = new SpeciesTreeNavModeReceiver(eventbus, pnl.getId());
		SpeciesTreeInvestigationModeReceiver receiverSelect = new SpeciesTreeInvestigationModeReceiver(
				eventbus, pnl.getId());

		addBroadcaster(pnl.getBroadcaster(), receiverNav, buildBroadcastCommand(pnl.getId()));
		addBroadcaster(pnl.getBroadcaster(), receiverSelect, buildBroadcastCommand(pnl.getId()));

		receiversNav.add(receiverNav);
		receiversSelect.add(receiverSelect);

		containerOuter.add(pnl);
		
		layout();
	}

	private void addGeneTreePanel(LayoutContainer containerOuter, TreeChannelPanel pnl)
	{
		GeneTreeNavModeReceiver receiverNav = new GeneTreeNavModeReceiver(eventbus, pnl.getId());
		GeneTreeInvestigationModeReceiver receiverSelect = new GeneTreeInvestigationModeReceiver(
				eventbus, pnl.getId());

		addBroadcaster(pnl.getBroadcaster(), receiverNav, buildBroadcastCommand(pnl.getId()));
		addBroadcaster(pnl.getBroadcaster(), receiverSelect, buildBroadcastCommand(pnl.getId()));

		receiversNav.add(receiverNav);
		receiversSelect.add(receiverSelect);

		containerOuter.add(pnl);
		layout();
	}

	private void buildNavButton()
	{
		btnNav = PanelHelper.buildToggleButton("idNavBtn", "Navigate",
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
		btnSelect = PanelHelper.buildToggleButton("idInvestigationBtn", "Investigation",
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

	private ToolBar buildToolbar()
	{
		ToolBar ret = new ToolBar();

		buildNavButton();
		buildSelectButton();

		ret.setAlignment(HorizontalAlignment.CENTER);

		ret.add(btnNav);
		ret.add(btnSelect);

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
		
		treeRetriever.getSpeciesTree(null, new SpeciesTreeRetrieverCallBack());

		// show
		add(pnlOuter);
	}
	
	private class SpeciesTreeRetrieverCallBack extends TreeRetrieverCallBack
	{
		@Override
		public void execute()
		{
			addSpeciesTreePanel(pnlOuter, new SpeciesTreeChannelPanel(eventbus, "Species Tree",
					"idSpeciesTree", getTree(), getLayout(), "pg00892"));
			treeRetriever.getGeneTree(null, new GeneTreeRetrieverCallBack());
		}
		
	}
	
	private class GeneTreeRetrieverCallBack extends TreeRetrieverCallBack
	{
		@Override
		public void execute()
		{
			addGeneTreePanel(pnlOuter, new GeneTreeChannelPanel(eventbus, "Gene Tree", "idGeneTree",
			getTree(), getLayout(),"pg00892"));
			// set our default mode
			toggleMode(Mode.NAVIGATE);
		}
		
	}
	
}
