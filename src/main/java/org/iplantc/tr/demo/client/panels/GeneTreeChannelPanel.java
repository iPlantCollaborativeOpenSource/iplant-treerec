package org.iplantc.tr.demo.client.panels;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.EventBus;
import com.google.gwt.user.client.Random;

/**
 * Channel panel containing species tree.
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
	 */
	public GeneTreeChannelPanel(EventBus eventbus, String caption, String id, String jsonTree,
			String layoutTree)
	{
		super(eventbus, caption, id, jsonTree, layoutTree);
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleGeneTreeInvestigationNodeSelect(int idNode, Point p)
	{
		treeView.clearHighlights();
		treeView.highlight(idNode);

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
		int cntNodes = treeView.getTree().getNumberOfNodes();

		treeView.clearHighlights();

		int id = 1 + Random.nextInt(cntNodes - 2);

		treeView.highlight(id);
		treeView.zoomToFitSubtree(id);
		
	}

	/**
	 * {@inheritDoc}
	 */
	protected void handleSpeciesTreeNavNodeSelect(int idNode, Point p)
	{
		int cntNodes = treeView.getTree().getNumberOfNodes();

		int id = 1 + Random.nextInt(cntNodes - 2);

		treeView.zoomToFitSubtree(id);
		
		
	}

	@Override
	protected void handleSpeciesTreeInvestigationEdgeSelect(int idEdgeToNode, Point point)
	{
		// TODO Auto-generated method stub
		
	}
	

}
