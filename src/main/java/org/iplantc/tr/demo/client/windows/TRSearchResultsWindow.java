package org.iplantc.tr.demo.client.windows;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.iplantc.tr.demo.client.JsTRSearchResult;
import org.iplantc.tr.demo.client.TRSearchResult;
import org.iplantc.tr.demo.client.commands.ClientCommand;
import org.iplantc.tr.demo.client.services.SearchServiceAsync;
import org.iplantc.tr.demo.client.utils.JsonUtil;
import org.iplantc.tr.demo.client.utils.TRUtil;

import com.extjs.gxt.ui.client.Style.HorizontalAlignment;
import com.extjs.gxt.ui.client.Style.SelectionMode;
import com.extjs.gxt.ui.client.data.BasePagingLoader;
import com.extjs.gxt.ui.client.data.PagingLoadResult;
import com.extjs.gxt.ui.client.data.PagingLoader;
import com.extjs.gxt.ui.client.data.PagingModelMemoryProxy;
import com.extjs.gxt.ui.client.event.BaseEvent;
import com.extjs.gxt.ui.client.event.Events;
import com.extjs.gxt.ui.client.event.Listener;
import com.extjs.gxt.ui.client.event.WindowEvent;
import com.extjs.gxt.ui.client.store.ListStore;
import com.extjs.gxt.ui.client.store.Store;
import com.extjs.gxt.ui.client.store.StoreSorter;
import com.extjs.gxt.ui.client.widget.ContentPanel;
import com.extjs.gxt.ui.client.widget.MessageBox;
import com.extjs.gxt.ui.client.widget.Window;
import com.extjs.gxt.ui.client.widget.button.Button;
import com.extjs.gxt.ui.client.widget.grid.ColumnConfig;
import com.extjs.gxt.ui.client.widget.grid.ColumnData;
import com.extjs.gxt.ui.client.widget.grid.ColumnModel;
import com.extjs.gxt.ui.client.widget.grid.Grid;
import com.extjs.gxt.ui.client.widget.grid.GridCellRenderer;
import com.extjs.gxt.ui.client.widget.layout.FitLayout;
import com.extjs.gxt.ui.client.widget.toolbar.PagingToolBar;
import com.google.gwt.core.client.JsArray;
import com.google.gwt.event.dom.client.ClickEvent;
import com.google.gwt.event.dom.client.ClickHandler;
import com.google.gwt.json.client.JSONObject;
import com.google.gwt.json.client.JSONValue;
import com.google.gwt.user.client.rpc.AsyncCallback;
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
	private SearchServiceAsync searchService;
	private String searchTerms;
	private String results;

	private static TRSearchResultsWindow instance;

	public static TRSearchResultsWindow getInstance()
	{
		if(instance == null)
		{
			instance = new TRSearchResultsWindow();
		}
		instance.hide();
		return instance;
	}

	private TRSearchResultsWindow() {
		addListener(Events.Show, new Listener<WindowEvent>() {

			@Override
			public void handleEvent(WindowEvent be)
			{
				init(searchTerms, results);
			}
		});
	}
	
	public void init(String searchTerms, String results, boolean showBlastColumns,
			ClientCommand cmdViewFamily, SearchServiceAsync searchService)
	{
		this.showBlastColumns = showBlastColumns;
		this.cmdViewFamily = cmdViewFamily;
		this.searchService = searchService;
		this.searchTerms = searchTerms;
		this.results = results;
		
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

		pnlGrid.layout(true);
		if(showBlastColumns)
		{
			// BLAST has two more columns
			setSize(800, 300);
		}
		else
		{
			setSize(640, 300);
		}
		layout(true);
	}

	private void compose()
	{
		removeAll();

		pnlGrid.add(gridResults);
		pnlGrid.setBottomComponent(pageBar);
		gridResults.getView().refresh(false);
		add(pnlGrid);

	}

	/**
	 * Builds the grid and the paging tool bar.
	 * 
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
		store.setStoreSorter(new TRResultsSorter());
		pageBar = new PagingToolBar(20);
		pageBar.bind(loader);
		loader.load(0, 20);

		final ColumnModel cm = buildColumnModel();

		gridResults = new Grid<TRSearchResult>(store, cm);

		gridResults.getSelectionModel().setSelectionMode(SelectionMode.MULTI);
		gridResults.setAutoExpandColumn("name");
		gridResults.getView().setSortingEnabled(true);
		
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
		//ret.setSortable(true);
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
		public Object render(final TRSearchResult result, String property, ColumnData config,
				int rowIndex, int colIndex, ListStore<TRSearchResult> store, Grid<TRSearchResult> grid)
		{
			HTML link = new HTML("<a href=\"#\">" + result.getName() + "</a>");
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
		public Object render(final TRSearchResult result, String property, ColumnData config,
				int rowIndex, int colIndex, ListStore<TRSearchResult> store, Grid<TRSearchResult> grid)
		{
			String goTermCount = result.getGoTermCount();
			if("0".equals(goTermCount))
			{
				return new HTML("0");
			}
			else
			{
				HTML link = new HTML(goTermCount + " <a href=\"#\"> (view all)</a>");
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
		}

		private void showWordCloud(TRSearchResult result)
		{
			String geneFamily = result.getName();
			searchService.getGoCloud(geneFamily, getCallback(geneFamily));
		}

		private AsyncCallback<String> getCallback(final String geneFamily)
		{
			return new AsyncCallback<String>()
			{
				@Override
				public void onFailure(Throwable arg0)
				{
					String err = "GO term cloud creation failed.";
					MessageBox.alert("Error", err + arg0.toString(), null);
				}

				@Override
				public void onSuccess(String result)
				{
					JSONValue html = TRUtil.parseItem(result);
					if(html != null)
					{
						JSONObject htmlObj = html.isObject();
						
						String cloud = JsonUtil.getString(htmlObj, "cloud");
						String categories = JsonUtil.getArrayString(htmlObj, "categories");
						
						//MessageBox.info("", categories, null);
						if(cloud != null)
						{
							WordCloudWindow window = WordCloudWindow.getInstance();
							window.setContents(cloud, geneFamily,categories);
							window.show();
							window.toFront();
						}
					}
				}
			};
		}

	}
	
	
	class TRResultsSorter extends StoreSorter<TRSearchResult>{
		
		@Override
		public int compare(Store<TRSearchResult> store, TRSearchResult m1,
				TRSearchResult m2, String property) {
			
			
			
			
			if(property.equals("numGenes") || property.equals("numSpecies") ||   property.equals("numDuplications") || property.equals("alignLength")) {
				
				Integer m11 = Integer.parseInt(m1.get(property).toString());
				Integer m22 = Integer.parseInt(m2.get(property).toString());
				return m11.compareTo(m22);
			}else if(property.equals("numGoTerms")){
				
				String[] values1 = m1.getGoTermCount().split(" ");
				String[] values2 = m2.getGoTermCount().split(" ");
				Integer m11 = Integer.parseInt(values1[0]);
				Integer m22 = Integer.parseInt(values2[0]);
				return m11.compareTo(m22);
			}else if(property.equals("eValue")) {
				Double m11 = Double.parseDouble(m1.get(property).toString());
				Double m22 = Double.parseDouble(m2.get(property).toString());
				return m11.compareTo(m22);
			}
			
			
			return super.compare(store, m1, m2, property);
		}
		
	}
	
	

}
