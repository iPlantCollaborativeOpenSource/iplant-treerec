package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.EventHandler;
import com.google.gwt.event.shared.GwtEvent;

/**
 * Abstract class for tree node selection events.
 * 
 * @author amuir
 * 
 * @param <H>
 */
public abstract class TreeNodeSelectEvent<H extends EventHandler> extends GwtEvent<H>
{
	protected int idNode;
	
	protected Point point;

	/**
	 * Instantiate from a node id and a point.
	 * 
	 * @param idNode unique id for the event firing node.
	 * @param point x,y coordinate in which user clicked
	 */
	protected TreeNodeSelectEvent(int idNode, Point point)
	{
		this.idNode = idNode;
		this.point = point;
	}

	/**
	 * Retrieve our node id.
	 * 
	 * @return unique id for the event firing node.
	 */
	public int getNodeId()
	{
		return idNode;
	}

	/**
	 * @return the point
	 */
	public Point getPoint()
	{
		return point;
	}
}
