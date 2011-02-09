package org.iplantc.tr.demo.client.utils;

import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.button.ToggleButton;

/**
 * Collection of methods to ensure UI panels are built correctly.
 * 
 * @author amuir
 * 
 */
public class PanelHelper
{
	/**
	 * Construct a button widget.
	 * 
	 * @param id id of button to create.
	 * @param text button text to display.
	 * @param listener event listener for button click.
	 * @return newly allocated button.
	 */
	public static Button buildButton(String id, String text, SelectionListener<ButtonEvent> listener)
	{
		Button ret = new Button(text, listener);

		ret.setId(id);

		return ret;
	}

	/**
	 * Construct a toggle button widget.
	 * 
	 * @param id id of button to create.
	 * @param text button text to display.
	 * @param listener event listener for button click.
	 * @return newly allocated button.
	 */
	public static ToggleButton buildToggleButton(String id, String text,
			SelectionListener<ButtonEvent> listener)
	{
		ToggleButton ret = new ToggleButton(text, listener);

		ret.setId(id);

		return ret;
	}
}
