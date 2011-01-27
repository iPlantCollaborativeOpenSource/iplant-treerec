package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.EventHandler;

/**
 * Handler for species tree navigation mode node selection events.
 * 
 * @author amuir
 * 
 */
public interface SpeciesTreeNavNodeSelectEventHandler extends EventHandler
{
	/**
	 * Called when the event is fired.
	 * 
	 * @param event firing event.
	 */
	void onFire(SpeciesTreeNavNodeSelectEvent event);
}
