package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;

import org.iplantc.tr.demo.client.events.HighlightNodesInGeneTreeEvent;
import org.iplantc.tr.demo.client.events.HighlightBranchesInSpeciesTreeEvent;
import org.iplantc.tr.demo.client.events.HighlightBranchesInSpeciesTreeEventHandler;
import org.iplantc.tr.demo.client.events.HighlightNodesInSpeciesTreeEvent;
import org.iplantc.tr.demo.client.events.HighlightNodesInSpeciesTreeEventHandler;
import org.iplantc.tr.demo.client.events.HighlightSpeciesSubTreeEvent;
import org.iplantc.tr.demo.client.events.HighlightSpeciesSubTreeEventHandler;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationEdgeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationEdgeSelectEventHandler;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationNodeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.SpeciesTreeNavNodeSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeNavNodeSelectEventHandler;
import org.iplantc.tr.demo.client.services.TreeServices;
import org.iplantc.tr.demo.client.utils.JsonUtil;

import com.extjs.gxt.ui.client.event.MenuEvent;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.util.Point;
import com.extjs.gxt.ui.client.widget.menu.Menu;
import com.extjs.gxt.ui.client.widget.menu.MenuItem;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.json.client.JSONArray;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.user.client.rpc.AsyncCallback;

/**
 * Channel panel that contains a species tree.
 * 
 * @author amuir
 * 
 */
public class SpeciesTreeChannelPanel extends NavTreeChannelPanel
{
	private String geneFamName;

	/**
	 * Instantiate from an event bus, caption, id, tree and layout
	 * 
	 * @param eventbus event bus for firing/receiving events.
	 * @param caption text to display in panel heading.
	 * @param id unique id for this panel.
	 * @param jsonTree tree data.
	 * @param layoutTree layout data.
	 * @param geneFamName gene family Id
	 */
	public SpeciesTreeChannelPanel(EventBus eventbus, String caption, String id, String jsonTree,
			String layoutTree, String geneFamName,int w, int h)
	{
		super(eventbus, caption, id, jsonTree, layoutTree, w, h);

		this.geneFamName = geneFamName;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void initListeners()
	{
		super.initListeners();

		handlers.add(eventbus.addHandler(HighlightSpeciesSubTreeEvent.TYPE,
				new HighlightSpeciesSubTreeEventHandlerImpl()));

		handlers.add(eventbus.addHandler(SpeciesTreeInvestigationNodeSelectEvent.TYPE,
				new SpeciesTreeInvestigationNodeSelectEventHandlerImpl()));

		handlers.add(eventbus.addHandler(SpeciesTreeNavNodeSelectEvent.TYPE,
				new SpeciesTreeNavNodeSelectEventHandlerImpl()));

		handlers.add(eventbus.addHandler(SpeciesTreeInvestigationEdgeSelectEvent.TYPE,
				new SpeciesTreeInvestigationEdgeSelectEventHandlerImpl()));

		handlers.add(eventbus.addHandler(HighlightBranchesInSpeciesTreeEvent.TYPE,
				new HighlightBranchesInSpeciesTreeEventHandlerImpl()));
		handlers.add(eventbus.addHandler(HighlightNodesInSpeciesTreeEvent.TYPE,
				new HighlightNodesInSpeciesTreeEventHandlerImpl()));
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleSpeciesTreeNavNodeSelect(int idNode, Point p)
	{
		treeView.zoomToFitSubtree(idNode);
	}

	private void displayMenu(Point p, int idNode)
	{
		Menu menu = new Menu();

		menu.setData("idNode", idNode);
		menu.add(buildHighlightSpeciesMenuItem());
		menu.add(buildHighlightAllMenuItem());
		menu.add(buildSelectSubTreeMenuItem());

		menu.showAt(p.x, p.y);
	}

	private void highlighBranchs(ArrayList<Integer> idNodes)
	{
		for(int i = 0;i < idNodes.size();i++)
		{
			treeView.highlightBranch(idNodes.get(i));
		}
	}

	private MenuItem buildHighlightSpeciesMenuItem()
	{
		MenuItem item = new MenuItem("Highlight speciation event in gene tree");

		item.addSelectionListener(new HighlightSpeciationSelectionListener());

		return item;
	}

	private MenuItem buildHighlightAllMenuItem()
	{

		MenuItem item = new MenuItem("Highlight all descendants (in gene and species tree)");

		item.addSelectionListener(new SelectionListener<MenuEvent>()
		{
			@Override
			public void componentSelected(MenuEvent ce)
			{
				Menu m = (Menu)ce.getSource();
				fireHighlightSubTreeEvent(m);
				int idNode = Integer.parseInt(m.getData("idNode").toString());
				getGeneDescendants(idNode, false, true);
			}
		});

		return item;
	}

	private MenuItem buildSelectSubTreeMenuItem()
	{
		MenuItem item = new MenuItem("Select sub tree");
		item.addSelectionListener(new SelectionListener<MenuEvent>()
		{
			@Override
			public void componentSelected(MenuEvent ce)
			{
				fireHighlightSubTreeEvent((Menu)ce.getSource());
			}
		});

		return item;
	}

	private void fireHighlightSubTreeEvent(Menu m)
	{
		int idNode = Integer.parseInt(m.getData("idNode").toString());
		HighlightSpeciesSubTreeEvent event = new HighlightSpeciesSubTreeEvent(idNode);
		eventbus.fireEvent(event);
	}

	private class HighlightSpeciesSubTreeEventHandlerImpl implements HighlightSpeciesSubTreeEventHandler
	{
		@Override
		public void onFire(HighlightSpeciesSubTreeEvent event)
		{
			treeView.clearHighlights();
			treeView.highlightSubtree(event.getIdNode());
		}
	}

	private class HighlightSpeciationSelectionListener extends SelectionListener<MenuEvent>
	{
		@Override
		public void componentSelected(MenuEvent ce)
		{
			Menu m = (Menu)ce.getSource();
			int idNode = Integer.parseInt(m.getData("idNode").toString());
			getGeneDescendants(idNode, false, false);
		}
	}

	private void getGeneDescendants(final int idNode, boolean edgeSelected, boolean includeSubtree)
	{
		TreeServices.getRelationship("{\"familyName\":\"" + geneFamName + "\",\"speciesTreeNode\":"
				+ idNode + ",\"edgeSelected\":" + edgeSelected + ",\"includeSubtree\":" + includeSubtree
				+ "}", new AsyncCallback<String>()
		{
			@Override
			public void onSuccess(String result)
			{
				ArrayList<Integer> nodesToHighlight = new ArrayList<Integer>();
				JSONObject o1 = JsonUtil.getObject(JsonUtil.getObject(result), "data");
				if(o1 != null)
				{
					JSONArray gene_nodes = JsonUtil.getArray(o1, "item");
					for(int i = 0;i < gene_nodes.size();i++)
					{
						nodesToHighlight.add(Integer.parseInt(JsonUtil.trim(gene_nodes.get(i).isObject()
								.get("geneTreeNode").toString())));
					}
				}

				HighlightNodesInGeneTreeEvent event =
						new HighlightNodesInGeneTreeEvent(nodesToHighlight);
				eventbus.fireEvent(event);
			}

			@Override
			public void onFailure(Throwable arg0)
			{
				System.out.println(arg0.toString());
			}
		});
	}

	private class SpeciesTreeInvestigationNodeSelectEventHandlerImpl implements
			SpeciesTreeInvestigationNodeSelectEventHandler
	{
		@Override
		public void onFire(SpeciesTreeInvestigationNodeSelectEvent event)
		{
			displayMenu(event.getPoint(), event.getNodeId());
		}
	}

	private class SpeciesTreeNavNodeSelectEventHandlerImpl implements
			SpeciesTreeNavNodeSelectEventHandler
	{

		@Override
		public void onFire(SpeciesTreeNavNodeSelectEvent event)
		{
			treeView.zoomToFitSubtree(event.getNodeId());
		}
	}

	private class SpeciesTreeInvestigationEdgeSelectEventHandlerImpl implements
			SpeciesTreeInvestigationEdgeSelectEventHandler
	{
		@Override
		public void onFire(SpeciesTreeInvestigationEdgeSelectEvent e)
		{
			getGeneDescendants(e.getIdEdgeToNode(), true, false);
		}
	}

	private class HighlightBranchesInSpeciesTreeEventHandlerImpl implements
			HighlightBranchesInSpeciesTreeEventHandler
	{
		@Override
		public void onFire(HighlightBranchesInSpeciesTreeEvent event)
		{
			treeView.clearHighlights();
			ArrayList<Integer> idNodes = event.getNodesToHighlight();
			highlighBranchs(idNodes);
		}
	}

	private class HighlightNodesInSpeciesTreeEventHandlerImpl implements
			HighlightNodesInSpeciesTreeEventHandler
	{
		@Override
		public void onFire(HighlightNodesInSpeciesTreeEvent event)
		{
			treeView.clearHighlights();
			ArrayList<Integer> idNodes = event.getNodesToHighlight();
			highlighNodes(idNodes);
		}
	}

	private void highlighNodes(ArrayList<Integer> idNodes)
	{
		for(int i = 0;i < idNodes.size();i++)
		{
			treeView.highlightNode(idNodes.get(i));
		}

	}
}
