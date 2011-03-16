package org.iplantc.tr.demo.client;

import com.extjs.gxt.ui.client.Style;
import com.extjs.gxt.ui.client.widget.ProgressBar;
import com.google.gwt.user.client.Timer;

public class ContinousProgressBar extends ProgressBar {

	private boolean stopProgress = true;
	private Timer timer;
	private String updateText;
	
	public ContinousProgressBar(String caption) {
		setBounds(10, 10, 200, Style.DEFAULT);
		setHeight(60);
		updateText = caption;
		timer = new Timer() {
			int counter = 0;

			@Override
			public void run() {
				if (stopProgress) {
					updateProgress(10.0, updateText);
					return;
				}

				if (counter == 10) {
					counter = 0;
				}

				counter++;
				updateProgress(counter / 10.0,updateText);
				this.schedule(100);
			}
		};

	}

	public void start() {
		if (stopProgress) {
			timer.schedule(100);
			stopProgress = false;
		}
	}

	public void stop() {
		stopProgress = true;
	}

}

