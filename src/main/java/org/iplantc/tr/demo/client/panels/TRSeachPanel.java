/**
 * 
 */
package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;

import org.iplantc.tr.demo.client.EventBusContainer;
import org.iplantc.tr.demo.client.Hyperlink;
import org.iplantc.tr.demo.client.TRAdvancedSearchPanel;
import org.iplantc.tr.demo.client.receivers.Receiver;
import org.iplantc.tr.demo.client.receivers.SpeciesTreeInvestigationModeReceiver;
import org.iplantc.tr.demo.client.utils.TreeRetriever;
import org.iplantc.tr.demo.client.utils.TreeRetrieverCallBack;

import com.extjs.gxt.ui.client.event.BaseEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.widget.Component;
import com.extjs.gxt.ui.client.widget.Dialog;
import com.extjs.gxt.ui.client.widget.HorizontalPanel;
import com.extjs.gxt.ui.client.widget.Label;
import com.extjs.gxt.ui.client.widget.LayoutContainer;
import com.extjs.gxt.ui.client.widget.VerticalPanel;
import com.extjs.gxt.ui.client.widget.layout.CenterLayout;

/**
 * @author sriram
 *
 */
public class TRSeachPanel extends EventBusContainer
{

	TreeRetriever treeRetriever;
	VerticalPanel outerPanel;
	private ArrayList<Receiver> receiversSelect;
	
	
	public TRSeachPanel()
	{
		
		treeRetriever = new TreeRetriever();
		outerPanel = new VerticalPanel();
		receiversSelect = new ArrayList<Receiver>();
		compose();
	}
	
	private void compose()
	{
		setHeading("Tree Reconciliation");
		outerPanel.setSpacing(10);
		add(outerPanel);
		treeRetriever.getSpeciesTree(null, new SpeciesTreeRetrieverCallBack());
	}

	private Component buildAdvSearch()
	{
		return new Label("The Tree Reconciliation application will enable users to search" +
				" and explore the relationship between </br> a gene family of interest " +
				"and a species tree that contains this gene tree");
	}

	private Component buildInfoLabel()
	{
		HorizontalPanel pnl = new HorizontalPanel();
		pnl.add(new Label("For users with a specific gene or sequence of interest, please use the&nbsp;&nbsp;"));
		Hyperlink link = new Hyperlink("Advanced Search Options");
		link.addListener(Events.OnClick, new Listener<BaseEvent>()
				{
		
					@Override
					public void handleEvent(BaseEvent be)
					{
						TRAdvancedSearchPanel advPanel = new TRAdvancedSearchPanel();
						Dialog d = new Dialog();
						d.setLayout(new CenterLayout());
						d.setHeading("Search");
						d.setSize(413, 279);
						d.add(advPanel);
						d.show();
					}
				});
		pnl.add(link);
		return pnl;
	}
	
	private void addSpeciesTreePanel(LayoutContainer containerOuter, TreeChannelPanel pnl)
	{
		SpeciesTreeInvestigationModeReceiver receiverSelect = new SpeciesTreeInvestigationModeReceiver(
				eventbus, pnl.getId());

		addBroadcaster(pnl.getBroadcaster(), receiverSelect, buildBroadcastCommand(pnl.getId()));
	
		receiversSelect.add(receiverSelect);
	
		outerPanel.add(pnl);
		layout();
	}

	
	private class SpeciesTreeRetrieverCallBack extends TreeRetrieverCallBack
	{
		@Override
		public void execute()
		{
			outerPanel.add(buildAdvSearch());
			addSpeciesTreePanel(outerPanel, new TRSearchSpeciesChannelPanel(eventbus, "Species Tree",
					"idSearchSpeciesTree", getTree(), getLayout(),""));
			
			outerPanel.add(buildInfoLabel());
			layout();
			show();
		}
		
	}
}