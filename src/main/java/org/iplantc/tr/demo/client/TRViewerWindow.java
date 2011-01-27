package org.iplantc.tr.demo.client;

import com.extjs.gxt.ui.client.event.ComponentEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;
import com.google.gwt.user.client.Element;

public class TRViewerWindow extends Window
{
	private TRViewerPanel pnl;

	public TRViewerWindow(SearchServiceAsync searchService, String idGene) {
		setLayout(new FitLayout());
		pnl = new TRViewerPanel(searchService, idGene);
		add(pnl);
		setSize(936, 596);
	}
}
