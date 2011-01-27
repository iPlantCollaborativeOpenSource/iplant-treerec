package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.EventHandler;

/**
 * Handler for gene tree navigation mode node selection events.
 * 
 * @author amuir
 * 
 */
public interface GeneTreeNavNodeSelectEventHandler extends EventHandler
{
	/**
	 * Called when the event is fired.
	 * 
	 * @param event firing event.
	 */
	void onFire(GeneTreeNavNodeSelectEvent event);
}
