package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;

import org.iplantc.tr.demo.client.events.GeneTreeInvestigationNodeSelectEvent;
import org.iplantc.tr.demo.client.events.GeneTreeInvestigationNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.GeneTreeNavNodeSelectEvent;
import org.iplantc.tr.demo.client.events.GeneTreeNavNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.HighlightNodesInGeneTreeEvent;
import org.iplantc.tr.demo.client.events.HighlightNodesInGeneTreeEventHandler;
import org.iplantc.tr.demo.client.events.HighlightNodesInSpeciesTreeEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationLeafSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationLeafSelectEventHandler;
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
 * Channel panel containing gene tree.
 * 
 * @author amuir
 * 
 */
public class GeneTreeChannelPanel extends NavTreeChannelPanel
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
	 * @param geneFamName gene family id
	 */
	public GeneTreeChannelPanel(EventBus eventbus, String caption, String id, String jsonTree,
			String layoutTree, String geneFamName)
	{
		super(eventbus, caption, id, jsonTree, layoutTree);
		this.geneFamName = geneFamName;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void initListeners()
	{
		super.initListeners();

		handlers.add(eventbus.addHandler(HighlightNodesInGeneTreeEvent.TYPE,
				new HighlightNodesInGeneTreeEventHandlerImpl()));
		
		handlers.add(eventbus.addHandler(SpeciesTreeInvestigationLeafSelectEvent.TYPE,
				new SpeciesTreeInvestigationLeafSelectEventHandlerImpl()));
		
		handlers.add(eventbus.addHandler(GeneTreeInvestigationNodeSelectEvent.TYPE,
				new GeneTreeInvestigationNodeSelectEventHandlerImpl()));

		handlers.add(eventbus.addHandler(GeneTreeNavNodeSelectEvent.TYPE,
				new GeneTreeNavNodeSelectEventHandlerImpl()));
	}
	
	
	private void displayMenu(Point p, int idNode)
	{
		Menu menu = new Menu();

		menu.setData("idNode", idNode);
		menu.add(buildHighlightSpeciesMenuItem());
		menu.add(buildSelectSubTreeMenuItem());

		menu.showAt(p.x, p.y);
	}

	private MenuItem buildSelectSubTreeMenuItem()
	{
		MenuItem item = new MenuItem("Highlight gene tree descendants");

		item.addSelectionListener(new HighlightDescendantsSelectionListenerImpl());

		return item;
	}

	private MenuItem buildHighlightSpeciesMenuItem()
	{
		MenuItem item = new MenuItem("Highlight duplication event in species tree");

		item.addSelectionListener(new HighlightDupSelectionListenerImpl());

		return item;
	}

	private class HighlightNodesInGeneTreeEventHandlerImpl implements
			HighlightNodesInGeneTreeEventHandler
	{
		@Override
		public void onFire(HighlightNodesInGeneTreeEvent event)
		{
			treeView.clearHighlights();
			ArrayList<Integer> idNodes = event.getNodesToHighlight();
			highlightNodes(idNodes);
		}
	}

	private class SpeciesTreeInvestigationLeafSelectEventHandlerImpl implements
			SpeciesTreeInvestigationLeafSelectEventHandler
	{
		@Override
		public void onFire(SpeciesTreeInvestigationLeafSelectEvent event)
		{
			getGenesForSpecies(event.getIdNode());
		}
	}
	
	private class GeneTreeInvestigationNodeSelectEventHandlerImpl implements GeneTreeInvestigationNodeSelectEventHandler
	{
		@Override
		public void onFire(GeneTreeInvestigationNodeSelectEvent event)
		{
			displayMenu(event.getPoint(),event.getNodeId());
		}		
	}
	
	private class GeneTreeNavNodeSelectEventHandlerImpl implements GeneTreeNavNodeSelectEventHandler
	{
		@Override
		public void onFire(GeneTreeNavNodeSelectEvent event)
		{
			treeView.zoomToFitSubtree(event.getNodeId());			
		}		
	}
	
	private void highlightNodes(ArrayList<Integer> idNodes)
	{
		for(int i = 0;i < idNodes.size();i++)
		{
			treeView.highlightNode(idNodes.get(i));
		}
	}
	
	private class HighlightDescendantsSelectionListenerImpl extends SelectionListener<MenuEvent>
	{

		@Override
		public void componentSelected(MenuEvent ce)
		{
			Menu m = (Menu)ce.getSource();
			int idNode = Integer.parseInt(m.getData("idNode").toString());
			treeView.highlightSubtree(idNode);
		}
		
	}
	
	private class HighlightDupSelectionListenerImpl extends SelectionListener<MenuEvent>
	{

		@Override
		public void componentSelected(MenuEvent ce)
		{
			Menu m = (Menu)ce.getSource();
			int idNode = Integer.parseInt(m.getData("idNode").toString());
			getSpeciesDescendants(idNode,false,false);
		}
		
	}
	
	private void getSpeciesDescendants(final int idNode, boolean edgeSelected , boolean includeSubtree)
	{
		TreeServices.getRelationship("{\"familyName\":\"" + geneFamName
				+ "\",\"speciesTreeNode\":" + idNode + ",\"edgeSelected\":" + edgeSelected + ",\"includeSubtree\":"+ includeSubtree  + "}",
				new AsyncCallback<String>()
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
								nodesToHighlight.add(Integer.parseInt(JsonUtil.trim(gene_nodes
										.get(i).isObject().get("geneTreeNode").toString())));
							}
						}

						HighlightNodesInSpeciesTreeEvent event = new HighlightNodesInSpeciesTreeEvent(nodesToHighlight);
						eventbus.fireEvent(event);
					}

					@Override
					public void onFailure(Throwable arg0)
					{
						System.out.println(arg0.toString());
					}
				});
	}
	
	
	private void getGenesForSpecies (final int idNode)
	{
		TreeServices.getGeneForSpecies("{\"familyName\":\"" + geneFamName + "\",\"speciesTreeNode\":" + idNode + "}", new AsyncCallback<String>()
				{

					@Override
					public void onFailure(Throwable arg0)
					{
						// TODO Auto-generated method stub
						
					}

					@Override
					public void onSuccess(String result)
					{
						ArrayList<Integer> nodesToHighlight = new ArrayList<Integer>();
						JSONObject o1 = JsonUtil.getObject(JsonUtil.getObject(result), "data");
						if(o1 != null)
						{
							JSONObject gene_nodes_obj = JsonUtil.getObject(o1, "item");
							JSONArray gene_nodes = JsonUtil.getArray(gene_nodes_obj, "geneTreeNodes");
							for(int i = 0;i < gene_nodes.size();i++)
							{
								nodesToHighlight.add(Integer.parseInt(JsonUtil.trim(gene_nodes.get(i).toString())));
							}
						}

						HighlightNodesInGeneTreeEvent event = new HighlightNodesInGeneTreeEvent(nodesToHighlight);
						eventbus.fireEvent(event);
						
					}
				});
	}
}
