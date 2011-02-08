package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;

import org.iplantc.tr.demo.client.events.HighlightSpeciationInGeneTreeEvent;
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
import com.google.gwt.user.client.Random;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.rpc.AsyncCallback;

/**
 * Channel panel that contains a species tree.
 * 
 * @author amuir
 * 
 */
public class SpeciesTreeChannelPanel extends TreeChannelPanel
{
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
			String layoutTree, String geneFamId)
	{
		super(eventbus, caption, id, jsonTree, layoutTree, geneFamId);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleGeneTreeInvestigationNodeSelect(int idNode, Point p)
	{
		int cntNodes = treeView.getTree().getNumberOfNodes();

		treeView.clearHighlights();

		int id = 1 + Random.nextInt(cntNodes - 2);

		treeView.highlight(id);
		treeView.zoomToFitSubtree(id);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleGeneTreeNavNodeSelect(int idNode, Point p)
	{
		int cntNodes = treeView.getTree().getNumberOfNodes();

		int id = 1 + Random.nextInt(cntNodes - 2);

		treeView.zoomToFitSubtree(id);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleSpeciesTreeInvestigationNodeSelect(int idNode, Point p)
	{
		// treeView.clearHighlights();
		// treeView.highlight(idNode);
		//
		// treeView.requestRender();

		displayMenu(p, idNode);
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

	private MenuItem buildSelectSubTreeMenuItem()
	{
		MenuItem item = new MenuItem("Highlight speciation event in gene tree");
				
		item.addSelectionListener(new HighlightSpeciationSelectionListener());
		
		return item;
	}

	private MenuItem buildHighlightAllMenuItem()
	{
		MenuItem item = new MenuItem("Highlight all descendants");
		
		item.addSelectionListener(new SelectionListener<MenuEvent>()
		{
			@Override
			public void componentSelected(MenuEvent ce)
			{
				//TODO implement me!!!
			}
		});

		return item;
	}

	private MenuItem buildHighlightSpeciesMenuItem()
	{
		MenuItem item = new MenuItem("Select sub tree (hide non selected species)");
		item.addSelectionListener(new SelectionListener<MenuEvent>()
		{
			@Override
			public void componentSelected(MenuEvent ce)
			{
				// TODO implement me!!!!
			}
		});

		return item;
	}

	@Override
	protected void handleSpeciesTreeInvestigationEdgeSelect(int idEdgeToNode, Point point)
	{
		Window.alert("clicked on edge");
	}
	
	private class HighlightSpeciationSelectionListener extends SelectionListener<MenuEvent>
	{
		@Override
		public void componentSelected(MenuEvent ce)
		{
			Menu m = (Menu)ce.getSource();
			int idNode = Integer.parseInt(m.getData("idNode").toString());
			TreeServices.getRelatedGeneEdgeNode("{\"familyName\":\"" + geneFamName  + "\",\"speciesTreeNode\":" + idNode + ",\"edgeSelected\":" + false  + "}", new AsyncCallback<String>()
			{				
				@Override
				public void onSuccess(String result)
				{
					ArrayList<Integer> nodesToHighlight = new ArrayList<Integer>();
					JSONObject o1 = JsonUtil.getObject(JsonUtil.getObject(result), "data");
					if (o1 != null)
					{
						JSONArray gene_nodes = JsonUtil.getArray(o1, "item");
						for (int i = 0;i <gene_nodes.size();i++)
						{
							nodesToHighlight.add(Integer.parseInt(JsonUtil.trim(gene_nodes.get(i).isObject().get("geneTreeNode").toString())));
						}
					}
					
					HighlightSpeciationInGeneTreeEvent event = new HighlightSpeciationInGeneTreeEvent(nodesToHighlight);
					eventbus.fireEvent(event);
				}
				
				@Override
				public void onFailure(Throwable arg0)
				{
					System.out.println(arg0.toString());
					
				}
			});			
		}		
	}
}
