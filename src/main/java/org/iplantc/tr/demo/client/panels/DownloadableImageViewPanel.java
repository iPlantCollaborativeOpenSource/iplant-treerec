package org.iplantc.tr.demo.client.panels;


import com.extjs.gxt.ui.client.Style.LayoutRegion;
import com.extjs.gxt.ui.client.Style.Scroll;
import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.layout.BorderLayout;
import com.extjs.gxt.ui.client.widget.layout.BorderLayoutData;
import com.extjs.gxt.ui.client.widget.toolbar.FillToolItem;
import com.extjs.gxt.ui.client.widget.toolbar.ToolBar;
import com.google.gwt.user.client.Element;
import com.google.gwt.user.client.Window;
import com.google.gwt.user.client.ui.Image;

public class DownloadableImageViewPanel extends ContentPanel
{
	private String urlDisplay;
	private String urlDownload;

	public DownloadableImageViewPanel(final String urlDisplay, final String urlDownload)
	{
		this.urlDisplay = urlDisplay;
		this.urlDownload = urlDownload;

		init();

		setTopComponent(buildButtonBar());
	}

	private void init()
	{
		setHeaderVisible(false);
		setBodyBorder(false);
		setBorders(false);
		setSize(918, 542);
	}

	private Button buildDownloadButton()
	{
		Button ret = PanelHelper.buildButton("btnDownload", "Download Image",
				new SelectionListener<ButtonEvent>()
				{
					@Override
					public void componentSelected(ButtonEvent ce)
					{
						if(urlDownload != null)
						{
							Window.open(urlDownload, null, "width=100,height=100");
						}
					}
				});

		// if we don't have download url... disable
		if(urlDownload == null)
		{
			ret.disable();
		}

		return ret;
	}

	private ToolBar buildButtonBar()
	{
		ToolBar ret = new ToolBar();

		ret.add(new FillToolItem());
		ret.add(buildDownloadButton());

		return ret;
	}

	private ContentPanel buildViewPanel()
	{
		ContentPanel ret = new ContentPanel();
		ret.setScrollMode(Scroll.AUTO);
		ret.setHeaderVisible(false);
		ret.setBodyBorder(false);
		ret.setStyleName("image-view-panel");
		ret.add(new Image(urlDisplay));
	
		return ret;
	}
	
	/**
	 * {@inheritDoc}
	 */
	@Override
	protected void onRender(Element parent, int index)
	{
		super.onRender(parent, index);

		setLayout(new BorderLayout());
		BorderLayoutData data = new BorderLayoutData(LayoutRegion.CENTER);
		
		if(urlDisplay != null)
		{						
			add(buildViewPanel(), data);
		}
	}
}
