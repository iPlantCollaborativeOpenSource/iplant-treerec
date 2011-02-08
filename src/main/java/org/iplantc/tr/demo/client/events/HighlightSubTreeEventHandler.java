package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.EventHandler;

public interface HighlightSubTreeEventHandler extends EventHandler
{
	@SuppressWarnings("unchecked")
	void onFire(HighlightSubTreeEvent event);
}
