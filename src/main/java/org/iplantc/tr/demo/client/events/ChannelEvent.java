package org.iplantc.tr.demo.client.events;

import com.google.gwt.event.shared.GwtEvent;

/**
 * Channel event fired when broadcaster broadcasts a message.
 * 
 * @author amuir
 * 
 */
public class ChannelEvent extends GwtEvent<ChannelEventHandler>
{
	public static final GwtEvent.Type<ChannelEventHandler> TYPE = new GwtEvent.Type<ChannelEventHandler>();

	private final String idBroadcaster;
	private final String jsonMsg;

	/**
	 * Instantiate from a broadcaster id and message.
	 * 
	 * @param idBroadcaster unique id of broadcaster firing this event.
	 * @param jsonMsg message associated with this event.
	 */
	public ChannelEvent(final String idBroadcaster, final String jsonMsg)
	{
		this.idBroadcaster = idBroadcaster;
		this.jsonMsg = jsonMsg;
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void dispatch(ChannelEventHandler handler)
	{
		handler.onFire(this);
	}

	/**
	 * {@inheritDoc}
	 */
	@Override
	public com.google.gwt.event.shared.GwtEvent.Type<ChannelEventHandler> getAssociatedType()
	{
		return TYPE;
	}

	/**
	 * Retrieve broadcaster id.
	 * 
	 * @return unique id of broadcaster who fired this event.
	 */
	public String getBroadcasterId()
	{
		return idBroadcaster;
	}

	/**
	 * Retrieve message associated with this event.
	 * 
	 * @return message JSON.
	 */
	public String getMessage()
	{
		return jsonMsg;
	}
}
