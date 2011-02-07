/**
 * 
 */
package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;

import org.iplantc.tr.demo.client.EventBusContainer;
import org.iplantc.tr.demo.client.Hyperlink;
import org.iplantc.tr.demo.client.receivers.Receiver;
import org.iplantc.tr.demo.client.receivers.SpeciesTreeInvestigationModeReceiver;
import org.iplantc.tr.demo.client.utils.TreeRetriever;
import org.iplantc.tr.demo.client.utils.TreeRetrieverCallBack;
import org.iplantc.tr.demo.client.windows.TRSearchWindow;

import com.extjs.gxt.ui.client.event.BaseEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.widget.Component;
import com.extjs.gxt.ui.client.widget.Label;
import com.extjs.gxt.ui.client.widget.LayoutContainer;
import com.extjs.gxt.ui.client.widget.VerticalPanel;

/**
 * @author sriram
 * 
 */
public class TRSearchPanel extends EventBusContainer
{
	TreeRetriever treeRetriever;
	VerticalPanel outerPanel;
	private ArrayList<Receiver> receiversSelect;

	public TRSearchPanel()
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
		return new Label("Explore the relationship between a gene family and its species tree.");
	}

	private Component buildInfoLabel()
	{		
		Hyperlink link = new Hyperlink("Advanced Search Options");
		link.addListener(Events.OnClick, new Listener<BaseEvent>()
		{
			@Override
			public void handleEvent(BaseEvent be)
			{
				TRSearchWindow window = TRSearchWindow.getInstance();
				window.show();
				window.toFront();
			}
		});

		return link;
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
					"idSearchSpeciesTree", getTree(), getLayout(), ""));

			outerPanel.add(buildInfoLabel());
			layout();
			show();
		}
	}
}
