package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.EventHandler;
import com.google.gwt.event.shared.GwtEvent;

public abstract class HighlightSubTreeEvent<H extends EventHandler> extends GwtEvent<H>
{

	private int idNode;
	
	/**
	 * @return the idNode
	 */
	public int getIdNode()
	{
		return idNode;
	}

	public HighlightSubTreeEvent(int idNode)
	{
		this.idNode = idNode;
	}
	

}