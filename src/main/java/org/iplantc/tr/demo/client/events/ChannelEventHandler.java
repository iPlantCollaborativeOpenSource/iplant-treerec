package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.EventHandler;

/**
 * Handler for channel events.
 * 
 * @author amuir
 * 
 */
public interface ChannelEventHandler extends EventHandler
{
	/**
	 * Called when the event is fired.
	 * 
	 * @param event firing event.
	 */
	void onFire(ChannelEvent event);
}
