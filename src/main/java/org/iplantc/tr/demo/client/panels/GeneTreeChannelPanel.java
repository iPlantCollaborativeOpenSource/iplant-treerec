package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;

import org.iplantc.tr.demo.client.events.GeneTreeInvestigationNodeSelectEvent;
import org.iplantc.tr.demo.client.events.GeneTreeInvestigationNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.GeneTreeNavNodeSelectEvent;
import org.iplantc.tr.demo.client.events.GeneTreeNavNodeSelectEventHandler;
import org.iplantc.tr.demo.client.events.HighlightSpeciationInGeneTreeEvent;
import org.iplantc.tr.demo.client.events.HighlightSpeciationInGeneTreeEventHandler;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationLeafSelectEvent;
import org.iplantc.tr.demo.client.events.SpeciesTreeInvestigationLeafSelectEventHandler;

import com.google.gwt.event.shared.EventBus;

/**
 * Channel panel containing gene tree.
 * 
 * @author amuir
 * 
 */
public class GeneTreeChannelPanel extends NavTreeChannelPanel
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
			String layoutTree)
	{
		super(eventbus, caption, id, jsonTree, layoutTree);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void initListeners()
	{
		super.initListeners();

		handlers.add(eventbus.addHandler(HighlightSpeciationInGeneTreeEvent.TYPE,
				new HighlightSpeciationInGeneTreeEventHandlerImpl()));
		
		handlers.add(eventbus.addHandler(SpeciesTreeInvestigationLeafSelectEvent.TYPE,
				new SpeciesTreeInvestigationLeafSelectEventHandlerImpl()));
		
		handlers.add(eventbus.addHandler(GeneTreeInvestigationNodeSelectEvent.TYPE,
				new GeneTreeInvestigationNodeSelectEventHandlerImpl()));

		handlers.add(eventbus.addHandler(GeneTreeNavNodeSelectEvent.TYPE,
				new GeneTreeNavNodeSelectEventHandlerImpl()));
	}

	private class HighlightSpeciationInGeneTreeEventHandlerImpl implements
			HighlightSpeciationInGeneTreeEventHandler
	{
		@Override
		public void onFire(HighlightSpeciationInGeneTreeEvent event)
		{
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
			ArrayList<Integer> idNodes = event.getGeneTreeNodesToSelect();
			highlightNodes(idNodes);
		}
	}

	private class GeneTreeInvestigationNodeSelectEventHandlerImpl implements GeneTreeInvestigationNodeSelectEventHandler
	{
		@Override
		public void onFire(GeneTreeInvestigationNodeSelectEvent event)
		{
			treeView.clearHighlights();
			treeView.highlightNode(event.getNodeId());
			treeView.requestRender();			
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
}
