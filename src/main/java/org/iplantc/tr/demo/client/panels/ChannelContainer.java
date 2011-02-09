package org.iplantc.tr.demo.client.panels;

import java.util.ArrayList;
import java.util.List;

import org.iplantc.core.broadcaster.shared.BroadcastCommand;
import org.iplantc.core.broadcaster.shared.Broadcaster;
import org.iplantc.tr.demo.client.receivers.Receiver;

import com.extjs.gxt.ui.client.widget.ContentPanel;

/**
 * Abstract channel container extending a GXT ContentPanel.
 * 
 * @author amuir
 * 
 */
public abstract class ChannelContainer extends ContentPanel
{
	protected List<Receiver> receivers;

	/**
	 * Default constructor.
	 */
	protected ChannelContainer()
	{
		init();

		receivers = new ArrayList<Receiver>();
	}

	/**
	 * ContentPanel initialization.
	 */
	protected void init()
	{
		setHeading("Viewers");
	}

	/**
	 * Adds a broadcaster to our container.
	 * 
	 * @param broadcaster broadcaster to add.
	 * @param receiver receiver to use with our broadcaster.
	 * @param cmdBroadcast command pattern implementation for allowing message broadcasting.
	 */
	public void addBroadcaster(final Broadcaster broadcaster, final Receiver receiver,
			BroadcastCommand cmdBroadcast)
	{
		if(broadcaster != null)
		{
			// set command for handling events
			broadcaster.setBroadcastCommand(cmdBroadcast);

			// do we have a valid receiver to add?
			if(receiver != null)
			{
				receivers.add(receiver);
			}
		}
	}
}
