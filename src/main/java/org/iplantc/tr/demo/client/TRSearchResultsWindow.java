package org.iplantc.tr.demo.client;

import java.util.ArrayList;
import java.util.List;

import org.iplantc.tr.demo.client.images.Resources;

import com.extjs.gxt.ui.client.Style.HorizontalAlignment;
import com.extjs.gxt.ui.client.Style.SelectionMode;
import com.extjs.gxt.ui.client.data.BasePagingLoader;
import com.extjs.gxt.ui.client.data.PagingLoadResult;
import com.extjs.gxt.ui.client.data.PagingLoader;
import com.extjs.gxt.ui.client.data.PagingModelMemoryProxy;
import com.extjs.gxt.ui.client.event.BaseEvent;
import com.extjs.gxt.ui.client.event.ButtonEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.event.SelectionListener;
import com.extjs.gxt.ui.client.store.ListStore;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.grid.ColumnConfig;
import com.extjs.gxt.ui.client.widget.grid.ColumnData;
import com.extjs.gxt.ui.client.widget.grid.ColumnModel;
import com.extjs.gxt.ui.client.widget.grid.Grid;
import com.extjs.gxt.ui.client.widget.grid.GridCellRenderer;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;
import com.extjs.gxt.ui.client.widget.toolbar.FillToolItem;
import com.extjs.gxt.ui.client.widget.toolbar.PagingToolBar;
import com.extjs.gxt.ui.client.widget.toolbar.ToolBar;
import com.google.gwt.core.client.JsArray;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.user.client.ui.AbstractImagePrototype;
import com.google.gwt.user.client.ui.HTML;

public class TRSearchResultsWindow extends Window
{
	private static final String TR_VIEW_BTN_ID = "idTRDataViewBtn";
	private Grid<TRSearchResult> gridResults;
	private boolean showBlastColumns;
	private ClientCommand cmdViewFamily;
	private ArrayList<Button> buttons;
	private ContentPanel pnlGrid;
	private PagingToolBar pageBar;

	public TRSearchResultsWindow(String searchTerms, String results, boolean showBlastColumns,
			ClientCommand cmdViewFamily)
	{
		this.showBlastColumns = showBlastColumns;
		this.cmdViewFamily = cmdViewFamily;
		init(searchTerms, results);
	}

	private void init(String heading, String results)
	{
		buttons = new ArrayList<Button>();
		setHeading("Tree Reconciliation Search Results");
		buildGrid(results);
		setLayout(new FitLayout());
		pnlGrid = new ContentPanel();
		pnlGrid.setLayout(new FitLayout());
		pnlGrid.setHeading(heading);
		compose();
		setSize(640, 300);
	}

	private void compose()
	{
		pnlGrid.add(gridResults);
		pnlGrid.setBottomComponent(pageBar);
		add(pnlGrid);
	}

	/**
	 * Builds the grid and the paging tool bar.
	 * @param json
	 */
	private void buildGrid(String json)
	{
		JsArray<JsTRSearchResult> arr = TRUtil.parseFamilies(json);

		List<TRSearchResult> results = new ArrayList<TRSearchResult>();
		if(arr != null)
		{
			for(int i = 0,len = arr.length();i < len;i++)
			{
				TRSearchResult item = new TRSearchResult(arr.get(i));
				results.add(item);
			}
		}

		PagingModelMemoryProxy proxy = new PagingModelMemoryProxy(results);
		PagingLoader<PagingLoadResult<?>> loader = new BasePagingLoader<PagingLoadResult<?>>(proxy);
		ListStore<TRSearchResult> store = new ListStore<TRSearchResult>(loader);
		pageBar = new PagingToolBar(20);
		pageBar.bind(loader);
		loader.load(0, 20);

		final ColumnModel cm = buildColumnModel();

		gridResults = new Grid<TRSearchResult>(store, cm);

		gridResults.getSelectionModel().setSelectionMode(SelectionMode.MULTI);
		gridResults.setAutoExpandColumn("name");

		gridResults.getView().setEmptyText("No results to display.");
		gridResults.getView().setForceFit(true);

		gridResults.getSelectionModel().addListener(Events.SelectionChange, new Listener<BaseEvent>()
		{
			@Override
			public void handleEvent(BaseEvent be)
			{
				if(gridResults.getSelectionModel().getSelectedItems().size() == 0)
				{
					disableButton(TR_VIEW_BTN_ID);
				}
				else
				{
					enableButton(TR_VIEW_BTN_ID);
				}
			}
		});
	}

	// build column with custom renderer
	private ColumnConfig buildConfig(String id, String caption, int width, HorizontalAlignment alignment)
	{
		ColumnConfig ret = new ColumnConfig(id, caption, width);

		ret.setMenuDisabled(true);
		ret.setSortable(false);
		ret.setAlignment(alignment);

		return ret;
	}

	private ColumnModel buildColumnModel()
	{
		List<ColumnConfig> config = new ArrayList<ColumnConfig>();

		ColumnConfig geneFamilyConfig = buildConfig("name", "Gene Family<br/>Identifier", 140,
				HorizontalAlignment.LEFT);
		geneFamilyConfig.setRenderer(new GeneFamilyColumnRenderer());
		config.add(geneFamilyConfig);

		if(showBlastColumns)
		{
			config.add(buildConfig("eValue", "E value", 80, HorizontalAlignment.CENTER));
			config.add(buildConfig("alignLength", "Length of<br/>Alignment", 80,
					HorizontalAlignment.CENTER));
		}

		config.add(buildConfig("goAnnotations", "Molecular Function/<br/>Biological Process", 200,
				HorizontalAlignment.LEFT));

		ColumnConfig goTermsConfig = buildConfig("numGoTerms", "Number of GO<br/>terms in family", 120,
				HorizontalAlignment.LEFT);
		goTermsConfig.setRenderer(new GoTermsColumnRenderer());
		config.add(goTermsConfig);

		config.add(buildConfig("numGenes", "Number of<br/>Genes", 80, HorizontalAlignment.CENTER));
		config.add(buildConfig("numSpecies", "Number of<br/>Species", 80, HorizontalAlignment.CENTER));
		config.add(buildConfig("numDuplications", "Number of<br/>Duplications", 80,
				HorizontalAlignment.CENTER));

		return new ColumnModel(config);
	}

	private String getSelectedGeneInfo()
	{
		String ret = null; // assume failure

		TRSearchResult result = gridResults.getSelectionModel().getSelectedItem();

		// do we have a selection?
		if(result != null)
		{
			ret = result.getName();
		}

		return ret;
	}

	private void launchViewers()
	{
		String name = getSelectedGeneInfo();

		// do we have any genes to view
		if(name != null)
		{
			cmdViewFamily.execute(name);
		}
	}

	private ToolBar buildButtonBar()
	{
		ToolBar ret = new ToolBar();

		ret.add(new FillToolItem());
		addButtons();

		// add all buttons to our toolbar
		for(Button btn : buttons)
		{
			ret.add(btn);
		}

		return ret;
	}

	private void addButton(String caption, String id, AbstractImagePrototype icon,
			SelectionListener<ButtonEvent> listener)
	{
		Button btn = new Button(caption, icon, listener);

		btn.setId(id);
		btn.setEnabled(false);
		btn.setHeight(23);

		buttons.add(btn);
	}

	private void addButtons()
	{
		buttons = new ArrayList<Button>();

		addButton("View", TR_VIEW_BTN_ID, AbstractImagePrototype.create(Resources.ICONS.listItems()),
				new SelectionListener<ButtonEvent>()
				{
					@Override
					public void componentSelected(ButtonEvent ce)
					{
						launchViewers();
					}
				});
	}

	private void enableButton(String id)
	{
		for(Button button : buttons)
		{
			if(button.getId().equals(id))
			{
				button.enable();
				pnlGrid.layout();
				break;
			}
		}
	}

	private void disableButton(String id)
	{
		for(Button button : buttons)
		{
			if(button.getId().equals(id))
			{
				button.disable();
				pnlGrid.layout();
				break;
			}
		}
	}

	/**
	 * A custom renderer for the Gene Family Identifier column
	 */
	class GeneFamilyColumnRenderer implements GridCellRenderer<TRSearchResult>
	{

		@Override
		public Object render(final TRSearchResult result, String property, ColumnData config, int rowIndex,
				int colIndex, ListStore<TRSearchResult> store, Grid<TRSearchResult> grid)
		{
			HTML link =  new HTML("<a href=\"#\">" + result.getName() + "</a>");
			link.addClickHandler(new ClickHandler()
			{
				@Override
				public void onClick(ClickEvent arg0)
				{
					cmdViewFamily.execute(result.getName());
				}
			});
			return link;
		}
	}

	/**
	 * A custom renderer for the Number of GO terms... column
	 */
	class GoTermsColumnRenderer implements GridCellRenderer<TRSearchResult>
	{

		@Override
		public Object render(final TRSearchResult result, String property, ColumnData config, int rowIndex,
				int colIndex, ListStore<TRSearchResult> store, Grid<TRSearchResult> grid)
		{
			HTML link = new HTML(result.getNumGoTerms() + " <a href=\"#\"> (view all)</a>");
			link.addClickHandler(new ClickHandler()
			{
				@Override
				public void onClick(ClickEvent arg0)
				{
					showWordCloud(result);
				}
			});
			return link;
		}
		
		private void showWordCloud(TRSearchResult result) {
			new WordCloudWindow().show();
		}
	}

}
