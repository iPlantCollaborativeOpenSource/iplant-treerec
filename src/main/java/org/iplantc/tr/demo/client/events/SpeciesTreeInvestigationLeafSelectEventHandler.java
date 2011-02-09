package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.EventHandler;

public interface SpeciesTreeInvestigationLeafSelectEventHandler extends EventHandler
{
	/**
	 * Called when the event is fired.
	 * 
	 * @param event firing event.
	 */
	void onFire(SpeciesTreeInvestigationLeafSelectEvent event);
}
