package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.GwtEvent;

public class TreeNodeMouseOverEvent extends GwtEvent<TreeNodeMouseOverEventHandler>
{

	public static final GwtEvent.Type<TreeNodeMouseOverEventHandler> TYPE = new GwtEvent.Type<TreeNodeMouseOverEventHandler>();
	
	private int idNode;
	private Point point;
	
	
	public TreeNodeMouseOverEvent(int idNode, Point point)
	{
		super();
		this.idNode = idNode;
		this.point = point;
	}

	/**
	 * @return the idNode
	 */
	public int getIdNode()
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

	@SuppressWarnings("unchecked")
	@Override
	public Type getAssociatedType()
	{
		return TYPE;
	}

	@Override
	protected void dispatch(TreeNodeMouseOverEventHandler handler)
	{
		handler.onMouseOver(this);
	}

}
