package org.iplantc.tr.demo.client.receivers;

/**
 * Base abstract receiver class.
 * 
 * @author amuir
 * 
 */
public abstract class Receiver
{
	private boolean isEnabled;

	/**
	 * Instantiate from enabled flag.
	 * 
	 * @param isEnabled enabled flag. true to enable this listener.
	 */
	protected Receiver(boolean isEnabled)
	{
		this.isEnabled = isEnabled;
	}

	/**
	 * Default constructor.
	 */
	protected Receiver()
	{
		this(true);
	}

	/**
	 * Enable listening for events.
	 */
	public void enable()
	{
		isEnabled = true;
	}

	/**
	 * Disable listening for events.
	 */
	public void disable()
	{
		isEnabled = false;
	}

	/**
	 * Query for enabled status.
	 * 
	 * @return true if enabled.
	 */
	public boolean isEnabled()
	{
		return isEnabled;
	}
}
