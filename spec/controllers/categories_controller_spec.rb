require 'spec_helper'

describe CategoriesController, "/index" do
  render_views

  before do
    3.times {
      category = Factory(:category)
      2.times { category.articles << Factory(:article) }
    }
  end

  describe "normally" do
    before do
      get 'index'
    end

    specify { response.should be_success }
    specify { response.should render_template('articles/groupings') }
    specify { assigns(:groupings).should_not be_empty }
    specify { response.body.should have_selector('ul.categorylist') }
  end

  describe "if :index template exists" do
    it "should render :index" do
      pending "Stubbing #template_exists is not enough to fool Rails"
      controller.stub!(:template_exists?) \
        .and_return(true)

      do_get
      response.should render_template(:index)
    end
  end
end

describe CategoriesController, '/articles/category/personal' do
  before do
    cat = Factory(:category, :permalink => 'personal', :name => 'Personal')
    cat.articles << contents(:article1)
    cat.articles << contents(:article2)
    cat.articles << contents(:article3)
    cat.articles << contents(:article4)
  end

  def do_get
    get 'show', :id => 'personal'
  end

  it 'should be successful' do
    do_get()
    response.should be_success
  end

  it 'should raise ActiveRecord::RecordNotFound' do
    Category.should_receive(:find_by_permalink) \
      .with('personal').and_raise(ActiveRecord::RecordNotFound)
    lambda do
      do_get
    end.should raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should render :show by default'
  if false
    controller.stub!(:template_exists?) \
      .and_return(true)
    do_get
    response.should render_template(:show)
  end

  it 'should fall back to rendering articles/index' do
    controller.stub!(:template_exists?) \
      .and_return(false)
    do_get
    response.should render_template('articles/index')
  end

  it 'should show only published articles' do
    c = Category.find_by_permalink("personal")
    c.articles.size.should == 4
    c.published_articles.size.should == 3

    do_get

    response.should be_success
    assigns[:articles].size.should == 3
  end

  it 'should set the page title to "Category Personal"' do
    do_get
    assigns[:page_title].should == 'Category Personal, everything about Personal'
  end

  it 'should render the atom feed for /articles/category/personal.atom' do
    get 'show', :id => 'personal', :format => 'atom'
    response.should render_template('articles/_atom_feed')
  end

  it 'should render the rss feed for /articles/category/personal.rss' do
    get 'show', :id => 'personal', :format => 'rss'
    response.should render_template('articles/_rss20_feed')
  end

end

describe CategoriesController, 'empty category life-on-mars' do
  it 'should redirect to home when the category is empty' do
    Factory(:category, :permalink => 'life-on-mars')
    get 'show', :id => 'life-on-mars'
    response.status.should == 301
    response.should redirect_to(Blog.default.base_url)
  end
end

describe CategoriesController, "password protected article" do
  render_views

  it 'should be password protected when shown in category' do
    cat = Factory(:category, :permalink => 'personal', :name => 'Personal')
    cat.articles << contents(:article1)
    cat.articles << contents(:article2)
    cat.articles << contents(:article3)
    cat.articles << contents(:article4)

    get 'show', :id => 'personal'

    assert_tag :tag => "input",
      :attributes => { :id => "article_password" }
  end
end

## Old tests that still need conversion

#   it "test_autodiscovery_category" do
#     get :category, :id => 'hardware'
#     assert_response :success
#     assert_select 'link[title=RSS]' do
#       assert_select '[rel=alternate]'
#       assert_select '[type=application/rss+xml]'
#       assert_select '[href=http://test.host/articles/category/hardware.rss]'
#     end
#     assert_select 'link[title=Atom]' do
#       assert_select '[rel=alternate]'
#       assert_select '[type=application/atom+xml]'
#       assert_select '[href=http://test.host/articles/category/hardware.atom]'
#     end
#   end
