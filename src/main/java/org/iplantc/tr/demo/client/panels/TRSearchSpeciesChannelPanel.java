/**
 * 
 */
package org.iplantc.tr.demo.client.panels;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.EventBus;

/**
 * @author sriram
 * 
 */
public class TRSearchSpeciesChannelPanel extends TreeChannelPanel
{

	public TRSearchSpeciesChannelPanel(EventBus eventbus, String caption, String id, String jsonTree,
			String layoutTree, String geneFamId)
	{
		super(eventbus, caption, id, jsonTree, layoutTree, geneFamId);
		setTopComponent(null);
		// TODO Auto-generated constructor stub
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.iplantc.tr.demo.client.panels.TreeChannelPanel#handleGeneTreeInvestigationNodeSelect(int,
	 * com.extjs.gxt.ui.client.util.Point)
	 */
	@Override
	protected void handleGeneTreeInvestigationNodeSelect(int idNode, Point point)
	{
		// TODO Auto-generated method stub

	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.iplantc.tr.demo.client.panels.TreeChannelPanel#handleGeneTreeNavNodeSelect(int,
	 * com.extjs.gxt.ui.client.util.Point)
	 */
	@Override
	protected void handleGeneTreeNavNodeSelect(int idNode, Point point)
	{
		// TODO Auto-generated method stub

	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * org.iplantc.tr.demo.client.panels.TreeChannelPanel#handleSpeciesTreeInvestigationEdgeSelect(int,
	 * com.extjs.gxt.ui.client.util.Point)
	 */
	@Override
	protected void handleSpeciesTreeInvestigationEdgeSelect(int idEdgeToNode, Point point)
	{
		// TODO Auto-generated method stub

	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * org.iplantc.tr.demo.client.panels.TreeChannelPanel#handleSpeciesTreeInvestigationNodeSelect(int,
	 * com.extjs.gxt.ui.client.util.Point)
	 */
	@Override
	protected void handleSpeciesTreeInvestigationNodeSelect(int idNode, Point point)
	{
		// TODO Auto-generated method stub

	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see org.iplantc.tr.demo.client.panels.TreeChannelPanel#handleSpeciesTreeNavNodeSelect(int,
	 * com.extjs.gxt.ui.client.util.Point)
	 */
	@Override
	protected void handleSpeciesTreeNavNodeSelect(int idNode, Point point)
	{
		// TODO Auto-generated method stub

	}

}
