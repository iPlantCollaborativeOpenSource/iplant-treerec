package org.iplantc.tr.demo.client.events;

import com.extjs.gxt.ui.client.util.Point;
import com.google.gwt.event.shared.GwtEvent;

public class TreeNodeMouseOutEvent extends GwtEvent<TreeNodeMouseOutEventHandler>
{

	public static final GwtEvent.Type<TreeNodeMouseOutEventHandler> TYPE =
			new GwtEvent.Type<TreeNodeMouseOutEventHandler>();

	private int idNode;
	private Point point;

	public TreeNodeMouseOutEvent(int idNode, Point point)
	{
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

	@Override
	protected void dispatch(TreeNodeMouseOutEventHandler handler)
	{
		handler.onMouseOut(this);
	}

	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<TreeNodeMouseOutEventHandler> getAssociatedType()
	{
		return TYPE;
	}

}
