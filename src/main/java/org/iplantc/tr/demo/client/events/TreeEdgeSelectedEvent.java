package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.EventHandler;
import com.google.gwt.event.shared.GwtEvent;

public abstract class TreeEdgeSelectedEvent<H extends EventHandler> extends GwtEvent<H>
{

	private int idEdgeToNode;
	
	private Point point;
	
	public TreeEdgeSelectedEvent(int idEdgeToNode, Point p)
	{
		this.idEdgeToNode = idEdgeToNode;
		this.point = p;
	}
	
	/**
	 * @return the point
	 */
	public Point getPoint()
	{
		return point;
	}
	
	
	/**
	 * @return the idEdgeToNode
	 */
	public int getIdEdgeToNode()
	{
		return idEdgeToNode;
	}


}
