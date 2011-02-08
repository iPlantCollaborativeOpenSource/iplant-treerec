package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;

import org.iplantc.tr.demo.client.events.HighlightSpeciationInGeneTreeEvent;
import org.iplantc.tr.demo.client.events.HighlightSpeciationInGeneTreeEventHandler;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.EventBus;

/**
 * Channel panel containing gene tree.
 * 
 * @author amuir
 * 
 */
public class GeneTreeChannelPanel extends TreeChannelPanel
{
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
			String layoutTree, String geneFamId)
	{
		super(eventbus, caption, id, jsonTree, layoutTree, geneFamId);
		eventbus.addHandler(HighlightSpeciationInGeneTreeEvent.TYPE, new HighlightSpeciationInGeneTreeEventHandlerImpl());
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleGeneTreeInvestigationNodeSelect(int idNode, Point p)
	{
		treeView.clearHighlights();
		treeView.highlightNode(idNode);
		treeView.requestRender();
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleGeneTreeNavNodeSelect(int idNode, Point p)
	{
		treeView.zoomToFitSubtree(idNode);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleSpeciesTreeInvestigationNodeSelect(int idNode, Point p)
	{
//		int cntNodes = treeView.getTree().getNumberOfNodes();
//
//		treeView.clearHighlights();
//
//		int id = 1 + Random.nextInt(cntNodes - 2);
//
//		treeView.highlight(id);
//		treeView.zoomToFitSubtree(id);
		
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleSpeciesTreeNavNodeSelect(int idNode, Point p)
	{
//		int cntNodes = treeView.getTree().getNumberOfNodes();
//
//		int id = 1 + Random.nextInt(cntNodes - 2);
//
//		treeView.zoomToFitSubtree(id);
		
		
	}

	@Override
	protected void handleSpeciesTreeInvestigationEdgeSelect(int idEdgeToNode, Point point)
	{
		// TODO Auto-generated method stub
		
	}
	
	private class HighlightSpeciationInGeneTreeEventHandlerImpl implements HighlightSpeciationInGeneTreeEventHandler
	{

		@Override
		public void onFire(HighlightSpeciationInGeneTreeEvent event)
		{
			ArrayList<Integer> idNodes = event.getNodesToHighlight();
			
			for (int i = 0 ;i < idNodes.size(); i++)
			{
				treeView.highlightNode(idNodes.get(i));
			}
			
		}
		
	}
	

}
