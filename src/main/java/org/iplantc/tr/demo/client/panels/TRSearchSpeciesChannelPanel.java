package org.iplantc.tr.demo.client.panels;

import com.google.gwt.event.shared.EventBus;

/**
 * Basic Tree Reconciliation search panel (search from a tree).
 * 
 * @author sriram
 * 
 */
public class TRSearchSpeciesChannelPanel extends TreeChannelPanel
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
	public TRSearchSpeciesChannelPanel(EventBus eventbus, String caption, String id, String jsonTree,
			String layoutTree)
	{
		super(eventbus, caption, id, jsonTree, layoutTree,0,0);
	}
}
